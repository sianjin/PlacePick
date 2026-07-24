import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Wraps a SharedPlaceIdentity so ShareLink can export a single Place as a named JSON file.
/// Same portability rules as TransferableCollectionSnapshot: identity only, per DATA_MODEL.md
/// "Shared Place Identity" — Collection, Favorite, Emotion, Note, and Memory Photo never travel.
struct TransferablePlaceIdentity: Transferable {
    let identity: SharedPlaceIdentity

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .placePickPlaceIdentity) { item in
            try JSONEncoder().encode(item.identity)
        }
        .suggestedFileName { item in
            "\(item.identity.name).placepickplace"
        }
    }
}
