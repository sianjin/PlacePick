import Foundation

/// The SF Symbol choices offered when creating or editing a Collection.
/// Shared by CollectionPickerSheet's inline creation flow and ManageCollectionsSheet's editor
/// so both stay in sync, per the "one responsibility per layer" / reuse principle.
enum CollectionIconChoices {
    static let all = [
        // Food & drink
        "fork.knife", "cup.and.saucer", "wineglass", "birthday.cake", "carrot",
        "basket", "takeoutbag.and.cup.and.straw",
        // Shopping & lodging
        "bag", "cart", "bed.double",
        // Places & city
        "building.columns", "building.2", "road.lanes", "road.lanes.curved.right",
        "graduationcap", "paintpalette",
        // Nature & outdoors
        "leaf", "tree", "mountain.2", "beach.umbrella", "tent", "fish", "pawprint",
        // Activities (grouped by kind: hike/run/ski/swim/sport together)
        "figure.hiking", "figure.run", "figure.skiing.downhill", "figure.pool.swim", "sportscourt", "bicycle",
        // Transportation (grouped together)
        "airplane", "train.side.front.car", "bus", "ferry", "fuelpump",
        // Entertainment
        "music.note", "theatermasks", "movieclapper", "popcorn", "gamecontroller", "gift", "book",
        // Feelings & keepsakes
        "heart", "star",
        // Weather & navigation
        "flag", "sun.max", "moon.stars",
        // Services
        "cross.case", "stethoscope", "wrench.and.screwdriver", "scissors"
    ]
}
