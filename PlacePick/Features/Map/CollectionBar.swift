import SwiftUI

struct CollectionBar: View {
    let collections: [PlaceCollection]
    @Binding var selectedCollection: PlaceCollection?
    let onManage: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CollectionChip(
                    title: "All",
                    icon: nil,
                    isSelected: selectedCollection == nil
                ) {
                    selectedCollection = nil
                }

                ForEach(collections) { collection in
                    CollectionChip(
                        title: collection.name,
                        icon: collection.icon,
                        isSelected: selectedCollection?.id == collection.id
                    ) {
                        selectedCollection = (selectedCollection?.id == collection.id) ? nil : collection
                    }
                }

                Button(action: onManage) {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline.weight(.medium))
                        .padding(8)
                        .background(Circle().fill(Color(.systemBackground)))
                        .overlay(Circle().strokeBorder(.separator, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            }
            .padding(.horizontal)
        }
    }
}

private struct CollectionChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected ? Color.accentColor : Color(.systemBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(Capsule().strokeBorder(.separator, lineWidth: isSelected ? 0 : 0.5))
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }
}
