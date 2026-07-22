import Foundation

/// The SF Symbol choices offered when creating or editing a Collection.
/// Shared by CollectionPickerSheet's inline creation flow and ManageCollectionsSheet's editor
/// so both stay in sync, per the "one responsibility per layer" / reuse principle.
enum CollectionIconChoices {
    static let all = [
        "fork.knife", "cup.and.saucer", "wineglass", "birthday.cake", "carrot",
        "bag", "cart", "bed.double", "building.columns",
        "beach.umbrella", "figure.hiking", "leaf", "tree", "mountain.2",
        "figure.skiing.downhill", "figure.pool.swim", "sportscourt", "figure.run", "bicycle",
        "camera", "music.note", "theatermasks", "ticket", "party.popper",
        "pawprint", "heart", "star", "sparkles", "gift",
        "airplane", "car", "train.side.front.car", "map", "flag",
        "sun.max", "moon.stars", "snowflake", "drop", "flame",
        "book", "gamecontroller", "guitars",
        "cross.case", "stethoscope", "wrench.and.screwdriver", "scissors", "fuelpump",
        "shower", "tent", "tree.circle", "fish", "bird",
        "sailboat", "ferry", "cablecar", "tram", "bus",
        "movieclapper", "popcorn", "surfboard"
    ]
}
