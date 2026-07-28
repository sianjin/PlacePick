import SwiftUI
import MapKit

/// Compact card shown when the user taps a native Apple Maps POI on MapScreen that isn't
/// already saved. Offers a fast path into the existing PersonalInfoForm/PlaceCreationService
/// pipeline without leaving the map.
struct POIPreviewCard: View {
    let mapItem: MKMapItem
    let onSave: () -> Void
    let onDismiss: () -> Void

    private var categorySymbol: String {
        mapItem.pointOfInterestCategory?.symbolName ?? "mappin"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categorySymbol)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(10)
                .background(Circle().fill(Color.accentColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(mapItem.name ?? "Unnamed Place")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let address = mapItem.oneLineAddress {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Button("Save", action: onSave)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 20))
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 6)
        .padding(.horizontal)
    }
}

private extension MKMapItem {
    /// `.address`/`MKAddress` (iOS 26+) replaces the deprecated `.placemark.title`;
    /// fall back to the old API on earlier OS versions still within our iOS 17 target.
    var oneLineAddress: String? {
        if #available(iOS 26.0, *) {
            return address?.shortAddress
        } else {
            return placemark.title
        }
    }
}

private extension MKPointOfInterestCategory {
    /// Best-effort icon for the preview card; falls back to a generic pin for categories
    /// without an obvious SF Symbol match.
    var symbolName: String {
        switch self {
        case .restaurant, .cafe, .bakery: return "fork.knife"
        case .park, .nationalPark: return "leaf"
        case .beach: return "beach.umbrella"
        case .museum: return "building.columns"
        case .hotel: return "bed.double"
        case .store, .foodMarket: return "cart"
        case .school, .university: return "graduationcap"
        case .hospital, .pharmacy: return "cross.case"
        default: return "mappin"
        }
    }
}
