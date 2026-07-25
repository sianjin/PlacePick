import Foundation
import SwiftData

@Model
final class PlaceCollection {
    var id: UUID = UUID()

    var name: String = ""
    var icon: String = ""
    var order: Int = 0

    /// Inverse of Place.collection — required by CloudKit ("all relationships must have an
    /// inverse"). Application code queries Places by Collection via #Predicate on Place
    /// directly (see CollectionRepository), not through this array.
    @Relationship(inverse: \Place.collection) var places: [Place]? = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        order: Int
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.order = order
    }
}

enum SuggestedCollection: CaseIterable {
    case food
    case drink
    case dessert
    case shopping
    case museum
    case hotel

    var name: String {
        switch self {
        case .food: return "Food"
        case .drink: return "Drink"
        case .dessert: return "Dessert"
        case .shopping: return "Shopping"
        case .museum: return "Museum"
        case .hotel: return "Hotel"
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .drink: return "cup.and.saucer"
        case .dessert: return "birthday.cake"
        case .shopping: return "bag"
        case .museum: return "building.columns"
        case .hotel: return "bed.double"
        }
    }
}
