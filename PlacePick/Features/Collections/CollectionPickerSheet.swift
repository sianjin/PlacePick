import SwiftUI
import SwiftData

/// Shared Collection picker used by both Add Place (§4.6) and direct Collection editing (§6.2).
/// Reused rather than reimplemented per the "reuse existing flows" architecture principle.
struct CollectionPickerSheet: View {
    @Binding var selection: PlaceCollection?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @State private var isPresentingNewCollection = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(collections) { collection in
                    Button {
                        selection = collection
                        dismiss()
                    } label: {
                        HStack {
                            Label(collection.name, systemImage: collection.icon)
                                .foregroundStyle(.primary)
                            Spacer()
                            if collection.id == selection?.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                Button {
                    isPresentingNewCollection = true
                } label: {
                    Label("New Collection", systemImage: "plus")
                }
            }
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $isPresentingNewCollection) {
                NewCollectionQuickSheet { newCollection in
                    selection = newCollection
                    dismiss()
                }
            }
        }
    }
}

private struct NewCollectionQuickSheet: View {
    let onCreate: (PlaceCollection) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var icon: String = "mappin"

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Collection name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CollectionIconChoices.all, id: \.self) { choice in
                            Button {
                                icon = choice
                            } label: {
                                Image(systemName: choice)
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle().fill(icon == choice ? Color.accentColor : Color(.secondarySystemBackground))
                                    )
                                    .foregroundStyle(icon == choice ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let repository = CollectionRepository(modelContext: modelContext)
                        let created = repository.create(name: trimmed, icon: icon)
                        onCreate(created)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
