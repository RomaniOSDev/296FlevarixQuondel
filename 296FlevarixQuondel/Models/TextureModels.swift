import Foundation
import SwiftUI
import UIKit

enum PatternKind: String, Codable, CaseIterable, Identifiable {
    case noise
    case dots
    case lines
    case grid
    case weave
    case crosshatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noise: return "Noise"
        case .dots: return "Dots"
        case .lines: return "Lines"
        case .grid: return "Grid"
        case .weave: return "Weave"
        case .crosshatch: return "Crosshatch"
        }
    }
}

enum TextureSortOrder: String, Codable, CaseIterable, Identifiable {
    case newest
    case name
    case usage
    case category
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: return "Newest"
        case .name: return "Name"
        case .usage: return "Usage"
        case .category: return "Category"
        case .favorites: return "Favorites"
        }
    }
}

enum TrendDateRange: String, Codable, CaseIterable, Identifiable {
    case week7
    case days30
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week7: return "7 Days"
        case .days30: return "30 Days"
        case .all: return "All Time"
        }
    }

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week7: return calendar.date(byAdding: .day, value: -7, to: Date())
        case .days30: return calendar.date(byAdding: .day, value: -30, to: Date())
        case .all: return nil
        }
    }
}

enum PreferredMetric: String, Codable, CaseIterable, Identifiable {
    case usage
    case popularity
    case creations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .usage: return "Usage"
        case .popularity: return "Popularity"
        case .creations: return "Creations"
        }
    }
}

struct TextureCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var symbol: String

    static let defaults: [TextureCategory] = [
        TextureCategory(id: "fabric", name: "Fabric", symbol: "square.grid.3x3.fill"),
        TextureCategory(id: "wood", name: "Wood", symbol: "leaf.fill"),
        TextureCategory(id: "metal", name: "Metal", symbol: "circle.hexagongrid.fill"),
        TextureCategory(id: "stone", name: "Stone", symbol: "mountain.2.fill"),
        TextureCategory(id: "paint", name: "Paint", symbol: "paintpalette.fill"),
        TextureCategory(id: "paper", name: "Paper", symbol: "doc.fill"),
        TextureCategory(id: "abstract", name: "Abstract", symbol: "sparkles"),
        TextureCategory(id: "custom", name: "Custom", symbol: "star.fill")
    ]

    static let symbolChoices = [
        "square.grid.3x3.fill", "leaf.fill", "circle.hexagongrid.fill", "mountain.2.fill",
        "paintpalette.fill", "doc.fill", "sparkles", "star.fill", "flame.fill",
        "drop.fill", "cube.fill", "waveform"
    ]
}

struct TextureItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var red: Double
    var green: Double
    var blue: Double
    var grain: Double
    var opacity: Double
    var patternScale: Double
    var patternKind: PatternKind
    var categoryId: String
    var createdAt: Date
    var updatedAt: Date
    var usageCount: Int
    var isFavorite: Bool
    var tags: [String]
    var patternAngle: Double
    var patternDensity: Double
    var patternThickness: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, red, green, blue, grain, opacity, patternScale, patternKind
        case categoryId, createdAt, updatedAt, usageCount, isFavorite
        case tags, patternAngle, patternDensity, patternThickness
    }

    init(
        id: UUID,
        name: String,
        red: Double,
        green: Double,
        blue: Double,
        grain: Double,
        opacity: Double,
        patternScale: Double,
        patternKind: PatternKind,
        categoryId: String,
        createdAt: Date,
        updatedAt: Date,
        usageCount: Int,
        isFavorite: Bool,
        tags: [String] = [],
        patternAngle: Double = 0.35,
        patternDensity: Double = 0.55,
        patternThickness: Double = 0.45
    ) {
        self.id = id
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
        self.grain = grain
        self.opacity = opacity
        self.patternScale = patternScale
        self.patternKind = patternKind
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.usageCount = usageCount
        self.isFavorite = isFavorite
        self.tags = tags
        self.patternAngle = patternAngle
        self.patternDensity = patternDensity
        self.patternThickness = patternThickness
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        red = try c.decode(Double.self, forKey: .red)
        green = try c.decode(Double.self, forKey: .green)
        blue = try c.decode(Double.self, forKey: .blue)
        grain = try c.decode(Double.self, forKey: .grain)
        opacity = try c.decode(Double.self, forKey: .opacity)
        patternScale = try c.decode(Double.self, forKey: .patternScale)
        patternKind = try c.decode(PatternKind.self, forKey: .patternKind)
        categoryId = try c.decode(String.self, forKey: .categoryId)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        usageCount = try c.decode(Int.self, forKey: .usageCount)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        patternAngle = try c.decodeIfPresent(Double.self, forKey: .patternAngle) ?? 0.35
        patternDensity = try c.decodeIfPresent(Double.self, forKey: .patternDensity) ?? 0.55
        patternThickness = try c.decodeIfPresent(Double.self, forKey: .patternThickness) ?? 0.45
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(red, forKey: .red)
        try c.encode(green, forKey: .green)
        try c.encode(blue, forKey: .blue)
        try c.encode(grain, forKey: .grain)
        try c.encode(opacity, forKey: .opacity)
        try c.encode(patternScale, forKey: .patternScale)
        try c.encode(patternKind, forKey: .patternKind)
        try c.encode(categoryId, forKey: .categoryId)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(usageCount, forKey: .usageCount)
        try c.encode(isFavorite, forKey: .isFavorite)
        try c.encode(tags, forKey: .tags)
        try c.encode(patternAngle, forKey: .patternAngle)
        try c.encode(patternDensity, forKey: .patternDensity)
        try c.encode(patternThickness, forKey: .patternThickness)
    }

    static func fresh(
        name: String = "",
        color: Color = Color(red: 1, green: 0, blue: 0.565),
        grain: Double = 0.35,
        opacity: Double = 0.85,
        patternScale: Double = 0.5,
        patternKind: PatternKind = .noise,
        categoryId: String = "custom",
        tags: [String] = [],
        patternAngle: Double = 0.35,
        patternDensity: Double = 0.55,
        patternThickness: Double = 0.45
    ) -> TextureItem {
        let ui = UIColor(color)
        var r: CGFloat = 1, g: CGFloat = 0, b: CGFloat = 0.565, a: CGFloat = 1
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let now = Date()
        return TextureItem(
            id: UUID(),
            name: name,
            red: Double(r),
            green: Double(g),
            blue: Double(b),
            grain: grain,
            opacity: opacity,
            patternScale: patternScale,
            patternKind: patternKind,
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
            usageCount: 0,
            isFavorite: false,
            tags: tags,
            patternAngle: patternAngle,
            patternDensity: patternDensity,
            patternThickness: patternThickness
        )
    }

    func duplicated(nameSuffix: String = " Copy") -> TextureItem {
        var copy = self
        copy.id = UUID()
        copy.name = name.isEmpty ? "Texture\(nameSuffix)" : name + nameSuffix
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.usageCount = 0
        copy.isFavorite = false
        return copy
    }
}

struct UserPattern: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var patternKind: PatternKind
    var patternScale: Double
    var grain: Double
    var createdAt: Date
}

struct TextureAnalyticsEvent: Identifiable, Codable, Hashable {
    var id: UUID
    var textureId: UUID?
    var categoryId: String
    var kind: String
    var value: Double
    var date: Date
}

struct DailyChallenge: Identifiable {
    let id: String
    let title: String
    let prompt: String
    let patternKind: PatternKind
    let categoryId: String
    let grain: Double
    let colorHex: String

    static var today: DailyChallenge {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let kinds = PatternKind.allCases
        let cats = TextureCategory.defaults
        let colors = ["FF0090", "E85D04", "2A9D8F", "577590", "9B5DE5", "F15BB5", "00BBF9", "FEE440"]
        let titles = [
            "Warm Weave", "Cool Metal", "Soft Paper", "Stone Grain",
            "Ink Hatch", "Neon Dust", "Forest Grid", "Velvet Dots"
        ]
        let prompts = [
            "Craft a tactile weave with gentle grain.",
            "Build a cool metallic surface with tight lines.",
            "Keep it airy — soft paper grain, low contrast.",
            "Heavy stone feel with dense cross texture.",
            "Classic ink hatch, angled and crisp.",
            "Playful neon dust with visible speckles.",
            "Organic forest grid, medium scale.",
            "Velvet dots, soft opacity, rich base."
        ]
        let idx = (day - 1) % titles.count
        return DailyChallenge(
            id: "day-\(day)",
            title: titles[idx],
            prompt: prompts[idx],
            patternKind: kinds[day % kinds.count],
            categoryId: cats[day % cats.count].id,
            grain: 0.25 + Double(day % 5) * 0.12,
            colorHex: colors[day % colors.count]
        )
    }
}

enum InspirePresets {
    static func random() -> TextureItem {
        let presets: [(PatternKind, String, Double, Double, Double, String)] = [
            (.weave, "fabric", 0.4, 0.7, 0.55, "C45C26"),
            (.lines, "metal", 0.25, 0.9, 0.4, "8D99AE"),
            (.noise, "paper", 0.55, 0.8, 0.65, "F4F1DE"),
            (.crosshatch, "stone", 0.65, 0.75, 0.5, "6D6875"),
            (.dots, "paint", 0.35, 0.85, 0.45, "E63946"),
            (.grid, "abstract", 0.3, 0.7, 0.6, "4CC9F0"),
            (.weave, "wood", 0.5, 0.8, 0.5, "BC6C25"),
            (.noise, "custom", 0.45, 0.9, 0.35, "FF0090")
        ]
        let pick = presets.randomElement() ?? presets[0]
        return TextureItem.fresh(
            name: "",
            color: Color(hex: pick.5),
            grain: pick.2 + Double.random(in: -0.08...0.08),
            opacity: min(1, max(0.2, pick.3 + Double.random(in: -0.1...0.1))),
            patternScale: min(1, max(0.1, pick.4 + Double.random(in: -0.15...0.15))),
            patternKind: pick.0,
            categoryId: pick.1,
            patternAngle: Double.random(in: 0.1...0.9),
            patternDensity: Double.random(in: 0.25...0.85),
            patternThickness: Double.random(in: 0.2...0.8)
        )
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 0, 144)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }

    func toHexString() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
