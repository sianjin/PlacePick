import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Wraps a SharedCollectionSnapshot so ShareLink can export it as a named JSON file.
/// The suggested filename carries the Collection name for a readable share-sheet preview;
/// the payload itself is the portable snapshot defined in DATA_MODEL.md.
struct TransferableCollectionSnapshot: Transferable {
    let snapshot: SharedCollectionSnapshot

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .placePickCollectionSnapshot) { item in
            try JSONEncoder().encode(item.snapshot)
        }
        .suggestedFileName { item in
            "\(item.snapshot.suggestedName).placepickcollection"
        }
    }
}
