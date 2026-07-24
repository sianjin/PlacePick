import SwiftUI
import SwiftData

struct ManageCollectionsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @State private var isPresentingNewCollection = false
    @State private var editingCollection: PlaceCollection?
    @State private var pendingDeletion: PlaceCollection?
    @State private var isReordering = false
    @State private var isPresentingSharePicker = false
    @State private var collectionAwaitingDeletion: (collection: PlaceCollection, destination: PlaceCollection?)?

    private var repository: CollectionRepository {
        CollectionRepository(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(collections) { collection in
                    Button {
                        editingCollection = collection
                    } label: {
                        HStack {
                            Image(systemName: collection.icon)
                                .frame(width: 24)
                            Text(collection.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            requestDelete(collection)
                        }
                    }
                }
                .onMove(perform: move)
            }
            .environment(\.editMode, .constant(isReordering ? .active : .inactive))
            .navigationTitle("Manage Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isReordering {
                        Button("Done") { isReordering = false }
                    } else {
                        Menu {
                            Button {
                                isPresentingSharePicker = true
                            } label: {
                                Label("Share Collection…", systemImage: "square.and.arrow.up")
                            }
                            .disabled(collections.isEmpty)

                            Button {
                                isReordering = true
                            } label: {
                                Label("Reorder", systemImage: "arrow.up.arrow.down")
                            }
                            .disabled(collections.count < 2)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        isPresentingNewCollection = true
                    } label: {
                        Label("New Collection", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewCollection) {
                CollectionEditorSheet(mode: .create) { name, icon in
                    repository.create(name: name, icon: icon)
                }
            }
            .sheet(item: $editingCollection) { collection in
                CollectionEditorSheet(mode: .edit(collection)) { name, icon in
                    repository.rename(collection, to: name)
                    repository.setIcon(collection, to: icon)
                }
            }
            .sheet(isPresented: $isPresentingSharePicker) {
                ShareCollectionPickerSheet(collections: collections, modelContext: modelContext)
            }
            .sheet(item: $pendingDeletion) { collection in
                DeleteCollectionSheet(
                    collection: collection,
                    otherCollections: collections.filter { $0.id != collection.id },
                    placeCount: repository.placeCount(for: collection),
                    onDelete: { destination in
                        pendingDeletion = nil
                        collectionAwaitingDeletion = (collection, destination)
                    },
                    onCancel: { pendingDeletion = nil }
                )
            }
            .onChange(of: pendingDeletion) { _, newValue in
                guard newValue == nil, let pending = collectionAwaitingDeletion else { return }
                collectionAwaitingDeletion = nil
                try? repository.delete(pending.collection, reassigningTo: pending.destination)
            }
        }
    }

    private func requestDelete(_ collection: PlaceCollection) {
        pendingDeletion = collection
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = collections
        reordered.move(fromOffsets: source, toOffset: destination)
        repository.reorder(reordered)
    }
}

private struct ShareCollectionPickerSheet: View {
    let collections: [PlaceCollection]
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(collections) { collection in
                HStack {
                    Image(systemName: collection.icon)
                        .frame(width: 24)
                    Text(collection.name)
                    Spacer()
                    ShareLink(
                        item: TransferableCollectionSnapshot(
                            snapshot: CollectionSnapshotBuilder.makeSnapshot(for: collection, modelContext: modelContext)
                        ),
                        preview: SharePreview(collection.name, image: sharePreviewBadgeImage(icon: collection.icon))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Share a Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct CollectionEditorSheet: View {
    enum Mode {
        case create
        case edit(PlaceCollection)
    }

    let mode: Mode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var icon: String

    init(mode: Mode, onSave: @escaping (String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _icon = State(initialValue: "mappin")
        case .edit(let collection):
            _name = State(initialValue: collection.name)
            _icon = State(initialValue: collection.icon)
        }
    }

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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, icon)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .create: return "New Collection"
        case .edit: return "Edit Collection"
        }
    }
}

private struct DeleteCollectionSheet: View {
    let collection: PlaceCollection
    let otherCollections: [PlaceCollection]
    let placeCount: Int
    let onDelete: (PlaceCollection?) -> Void
    let onCancel: () -> Void

    @State private var destination: PlaceCollection?

    var body: some View {
        NavigationStack {
            Form {
                if placeCount > 0 {
                    Section {
                        Text("\(placeCount) place\(placeCount == 1 ? "" : "s") belong\(placeCount == 1 ? "s" : "") to this Collection.")
                            .foregroundStyle(.secondary)
                    }

                    Section("Move places to") {
                        if otherCollections.isEmpty {
                            Text("Create another Collection first.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(otherCollections) { candidate in
                                Button {
                                    destination = candidate
                                } label: {
                                    HStack {
                                        Label(candidate.name, systemImage: candidate.icon)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if destination?.id == candidate.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Text("This Collection has no places.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Delete \"\(collection.name)\"?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Delete", role: .destructive) {
                        onDelete(destination)
                    }
                    .disabled(placeCount > 0 && destination == nil)
                }
            }
        }
    }
}
