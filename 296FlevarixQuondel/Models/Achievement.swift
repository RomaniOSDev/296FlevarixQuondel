import Foundation

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }
}

enum AchievementCatalog {
    static let all: [Achievement] = [
        Achievement(
            id: "first_creation",
            title: "First Creation",
            detail: "Create your first texture design.",
            symbol: "sparkle",
            unlockedAt: nil
        ),
        Achievement(
            id: "texture_novice",
            title: "Texture Novice",
            detail: "Create 10 textures in your library.",
            symbol: "paintbrush.pointed.fill",
            unlockedAt: nil
        ),
        Achievement(
            id: "experienced_designer",
            title: "Experienced Designer",
            detail: "Complete 25 design sessions.",
            symbol: "briefcase.fill",
            unlockedAt: nil
        ),
        Achievement(
            id: "library_enthusiast",
            title: "Library Enthusiast",
            detail: "Create 20 textures and finish 5 sessions.",
            symbol: "books.vertical.fill",
            unlockedAt: nil
        ),
        Achievement(
            id: "hundred_designs",
            title: "+100 Designs",
            detail: "Reach 100 textures with 50 sessions.",
            symbol: "rosette",
            unlockedAt: nil
        ),
        Achievement(
            id: "power_user",
            title: "Power User",
            detail: "Create 50 textures.",
            symbol: "bolt.fill",
            unlockedAt: nil
        ),
        Achievement(
            id: "active_user",
            title: "Active User",
            detail: "Complete 10 sessions.",
            symbol: "flame.fill",
            unlockedAt: nil
        ),
        Achievement(
            id: "dedicated_user",
            title: "Dedicated User",
            detail: "Complete 50 sessions.",
            symbol: "crown.fill",
            unlockedAt: nil
        )
    ]

    static func evaluate(itemsCreated: Int, sessionsCompleted: Int, existing: [Achievement]) -> (updated: [Achievement], newlyUnlocked: [Achievement]) {
        let unlockedMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0.unlockedAt) })
        var updated: [Achievement] = []
        var newly: [Achievement] = []
        let now = Date()

        for base in all {
            var item = base
            item.unlockedAt = unlockedMap[base.id] ?? nil
            let qualifies: Bool
            switch base.id {
            case "first_creation":
                qualifies = itemsCreated >= 1
            case "texture_novice":
                qualifies = itemsCreated >= 10
            case "experienced_designer":
                qualifies = sessionsCompleted >= 25
            case "library_enthusiast":
                qualifies = itemsCreated >= 20 && sessionsCompleted >= 5
            case "hundred_designs":
                qualifies = itemsCreated >= 100 && sessionsCompleted >= 50
            case "power_user":
                qualifies = itemsCreated >= 50
            case "active_user":
                qualifies = sessionsCompleted >= 10
            case "dedicated_user":
                qualifies = sessionsCompleted >= 50
            default:
                qualifies = false
            }
            if qualifies && item.unlockedAt == nil {
                item.unlockedAt = now
                newly.append(item)
            }
            updated.append(item)
        }
        return (updated, newly)
    }
}
