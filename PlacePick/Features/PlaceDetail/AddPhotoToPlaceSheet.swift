import SwiftUI
import PhotosUI
import SwiftData

/// Adds photos to a known Place as a new Memory — no clustering or Place confirmation,
/// since the Place is already fixed by where the user tapped Add Memory from. This is a
/// separate, simpler entry point than PhotoMemoryScreen's multi-group flow (MEMORY_CREATION.md
/// Stage 1–5), which exists for the "I don't know which photos go where yet" case.
///
/// Always creates a fresh Visit (DATA_MODEL.md §20 — a Place may have many Memories, and
/// Add Memory must be repeatable), never reuses an existing one.
struct AddPhotoToPlaceSheet: View {
    let place: Place
    let onSaved: (Visit) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var isPresentingPicker = false
    @State private var isLoading = false
    @State private var authorizationDenied = false
    @State private var loadErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                if authorizationDenied {
                    ContentUnavailableView(
                        "Photo Access Needed",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Allow full Photos access in Settings so PlacePick can read photo dates and locations.")
                    )
                } else {
                    ContentUnavailableView(
                        "Add a Memory",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Choose photos for a new memory at \(place.name).")
                    )
                }

                Button {
                    Task { await requestAccessThenPresentPicker() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Choose Photos")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(isLoading)

                Spacer()
            }
            .navigationTitle("Add Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .photosPicker(
                isPresented: $isPresentingPicker,
                selection: $pickerSelection,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: pickerSelection) { _, newValue in
                guard !newValue.isEmpty else { return }
                Task { await attach(newValue) }
            }
            .alert("Couldn't Read Photo Details", isPresented: .constant(loadErrorMessage != nil), actions: {
                Button("OK") {
                    loadErrorMessage = nil
                    pickerSelection = []
                }
            }, message: { Text(loadErrorMessage ?? "") })
        }
    }

    private func requestAccessThenPresentPicker() async {
        isLoading = true
        let status = await PhotoLibraryService.requestReadAccessIfNeeded()
        isLoading = false

        guard status == .authorized || status == .limited else {
            authorizationDenied = true
            return
        }
        authorizationDenied = false
        isPresentingPicker = true
    }

    private func attach(_ items: [PhotosPickerItem]) async {
        isLoading = true
        defer { isLoading = false }

        let candidates = await PhotoLibraryService.loadCandidates(for: items)
        guard !candidates.isEmpty else {
            loadErrorMessage = "PlacePick couldn't read the date for the selected photos. Photos need capture-date metadata (most camera photos have this; some screenshots or edited images may not)."
            return
        }

        let visit = Visit(place: place)
        modelContext.insert(visit)
        VisitPhotoRepository(modelContext: modelContext).attach(candidates, to: visit)

        onSaved(visit)
        dismiss()
    }
}
