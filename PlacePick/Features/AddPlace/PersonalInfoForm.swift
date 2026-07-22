import SwiftUI
import SwiftData
import MapKit

struct PersonalInfoForm: View {
    let mapItem: MKMapItem
    let onCancel: () -> Void
    let onSave: (PlaceRelationshipDraft) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @State private var selectedCollection: PlaceCollection?
    @State private var isPresentingCollectionPicker = false
    @State private var isFavorite: Bool = false
    @State private var emotion: PlaceEmotion?
    @State private var note: String = ""

    var body: some View {
        Form {
            Section {
                Text(mapItem.name ?? "Unnamed Place")
                    .font(.headline)
            }

            Section("Collection") {
                Button {
                    isPresentingCollectionPicker = true
                } label: {
                    if let selectedCollection {
                        Label(selectedCollection.name, systemImage: selectedCollection.icon)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Choose a Collection")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Toggle(isOn: $isFavorite) {
                    Label("Favorite", systemImage: isFavorite ? "star.fill" : "star")
                }

                EmotionPicker(emotion: $emotion)
            }

            Section("Note") {
                TextEditor(text: $note)
                    .frame(minHeight: 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let selectedCollection else { return }
                    let draft = PlaceRelationshipDraft(
                        collection: selectedCollection,
                        isFavorite: isFavorite,
                        emotion: emotion,
                        note: note
                    )
                    onSave(draft)
                }
                .disabled(selectedCollection == nil)
            }
        }
        .sheet(isPresented: $isPresentingCollectionPicker) {
            CollectionPickerSheet(selection: $selectedCollection)
        }
        .onAppear {
            if selectedCollection == nil {
                selectedCollection = collections.first
            }
        }
    }
}

struct EmotionPicker: View {
    @Binding var emotion: PlaceEmotion?

    private let options: [PlaceEmotion] = [.neutral, .happy, .amazed]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(options, id: \.self) { option in
                Button {
                    emotion = (emotion == option) ? nil : option
                } label: {
                    Text(option.symbolEmoji)
                        .font(.title2)
                        .opacity(emotion == nil || emotion == option ? 1.0 : 0.35)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
