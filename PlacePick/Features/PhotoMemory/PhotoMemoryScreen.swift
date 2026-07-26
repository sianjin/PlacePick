import SwiftUI
import PhotosUI
import Photos

/// Stage 1 (Choose Photos) and Stage 2 (Review Memory Groups) of Memory Creation.
/// See MEMORY_CREATION.md — the interface never exposes clustering, GPS matching, or
/// asset-identifier implementation details; only "photos" and "groups."
struct PhotoMemoryScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var stage: Stage = .choosingPhotos
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var draft = PhotoImportDraft()
    @State private var isLoadingMetadata = false
    @State private var authorizationDenied = false
    @State private var loadErrorMessage: String?
    @State private var isPresentingPicker = false

    private enum Stage {
        case choosingPhotos
        case reviewingGroups
        case reviewingAndCreating
        case created
    }

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .choosingPhotos:
                    choosePhotosStage
                case .reviewingGroups:
                    ReviewGroupsStage(draft: $draft, onContinue: { stage = .reviewingAndCreating })
                case .reviewingAndCreating:
                    ReviewAndCreateStage(draft: $draft, onCreated: { stage = .created })
                case .created:
                    createdConfirmation
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var choosePhotosStage: some View {
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
                    "Choose Photos",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Select photos from a visit to turn them into a Memory.")
                )
            }

            Button {
                Task { await requestAccessThenPresentPicker() }
            } label: {
                if isLoadingMetadata {
                    ProgressView()
                } else {
                    Text("Choose Photos")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(isLoadingMetadata)

            Spacer()
        }
        .photosPicker(
            isPresented: $isPresentingPicker,
            selection: $pickerSelection,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: pickerSelection) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task { await handleSelection(newValue) }
        }
        .alert("Couldn't Read Photo Details", isPresented: .constant(loadErrorMessage != nil), actions: {
            Button("OK") {
                loadErrorMessage = nil
                pickerSelection = []
            }
        }, message: { Text(loadErrorMessage ?? "") })
    }

    /// Requesting Photos authorization before presenting the picker (rather than after
    /// selection) avoids a race where PHAsset lookups run before the app's own process
    /// has been granted access to the just-picked assets.
    private func requestAccessThenPresentPicker() async {
        isLoadingMetadata = true
        let status = await PhotoLibraryService.requestReadAccessIfNeeded()
        isLoadingMetadata = false

        guard status == .authorized || status == .limited else {
            authorizationDenied = true
            return
        }
        authorizationDenied = false
        isPresentingPicker = true
    }

    private func handleSelection(_ items: [PhotosPickerItem]) async {
        isLoadingMetadata = true
        defer { isLoadingMetadata = false }

        let candidates = await PhotoLibraryService.loadCandidates(for: items)
        guard !candidates.isEmpty else {
            loadErrorMessage = "PlacePick couldn't read the date for the selected photos. Photos need capture-date metadata (most camera photos have this; some screenshots or edited images may not)."
            return
        }

        draft.selectedPhotos = candidates
        draft.proposedGroups = PhotoClusteringService.proposeGroups(from: candidates)
        stage = .reviewingGroups
    }

    private var createdConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Memories Saved")
                .font(.title2.weight(.semibold))
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }
}
