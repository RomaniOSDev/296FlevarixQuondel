import Foundation
import Combine
import SwiftUI
import UIKit

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.onboarding) }
    }

    @Published var textures: [TextureItem] = [] {
        didSet { saveCodable(textures, key: Keys.textures) }
    }

    @Published var categories: [TextureCategory] = TextureCategory.defaults {
        didSet { saveCodable(categories, key: Keys.categories) }
    }

    @Published var userPatterns: [UserPattern] = [] {
        didSet { saveCodable(userPatterns, key: Keys.userPatterns) }
    }

    @Published var textureAnalytics: [TextureAnalyticsEvent] = [] {
        didSet { saveCodable(textureAnalytics, key: Keys.analytics) }
    }

    @Published var sortOrder: TextureSortOrder = .newest {
        didSet { UserDefaults.standard.set(sortOrder.rawValue, forKey: Keys.sortOrder) }
    }

    @Published var trendDateRange: TrendDateRange = .week7 {
        didSet { UserDefaults.standard.set(trendDateRange.rawValue, forKey: Keys.trendRange) }
    }

    @Published var preferredMetrics: PreferredMetric = .usage {
        didSet { UserDefaults.standard.set(preferredMetrics.rawValue, forKey: Keys.preferredMetrics) }
    }

    @Published var lastUsedColorHex: String = "FF0090" {
        didSet { UserDefaults.standard.set(lastUsedColorHex, forKey: Keys.lastUsedColor) }
    }

    @Published var defaultGrain: Double = 0.35 {
        didSet { UserDefaults.standard.set(defaultGrain, forKey: Keys.defaultGrain) }
    }

    @Published var colorHistory: [String] = [] {
        didSet { saveCodable(colorHistory, key: Keys.colorHistory) }
    }

    @Published var achievements: [Achievement] = AchievementCatalog.all {
        didSet { saveCodable(achievements, key: Keys.achievements) }
    }

    @Published var itemsCreated: Int = 0 {
        didSet { UserDefaults.standard.set(itemsCreated, forKey: Keys.itemsCreated) }
    }

    @Published var streakDays: Int = 0 {
        didSet { UserDefaults.standard.set(streakDays, forKey: Keys.streak) }
    }

    @Published var totalSessionsCompleted: Int = 0 {
        didSet { UserDefaults.standard.set(totalSessionsCompleted, forKey: Keys.sessions) }
    }

    @Published var totalMinutesUsed: Int = 0 {
        didSet { UserDefaults.standard.set(totalMinutesUsed, forKey: Keys.minutes) }
    }

    @Published var bannerTitle: String?
    @Published var showSuccessFlash = false
    @Published var selectedTab: Int = 0

    private var sessionStartedAt: Date?
    private var lastActiveDay: String {
        get { UserDefaults.standard.string(forKey: Keys.lastActiveDay) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastActiveDay) }
    }

    private enum Keys {
        static let onboarding = "hasSeenOnboarding"
        static let textures = "textures"
        static let categories = "categories"
        static let userPatterns = "userPatterns"
        static let analytics = "textureAnalytics"
        static let sortOrder = "sortOrder"
        static let trendRange = "trendDateRange"
        static let preferredMetrics = "preferredMetrics"
        static let lastUsedColor = "lastUsedColor"
        static let defaultGrain = "defaultGrain"
        static let colorHistory = "colorHistory"
        static let achievements = "achievements"
        static let itemsCreated = "itemsCreated"
        static let streak = "streakDays"
        static let sessions = "totalSessionsCompleted"
        static let minutes = "totalMinutesUsed"
        static let lastActiveDay = "lastActiveDay"
    }

    private init() {
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: Keys.onboarding)
        textures = loadCodable([TextureItem].self, key: Keys.textures) ?? []
        categories = loadCodable([TextureCategory].self, key: Keys.categories) ?? TextureCategory.defaults
        if categories.isEmpty { categories = TextureCategory.defaults }
        userPatterns = loadCodable([UserPattern].self, key: Keys.userPatterns) ?? []
        textureAnalytics = loadCodable([TextureAnalyticsEvent].self, key: Keys.analytics) ?? []
        if let raw = UserDefaults.standard.string(forKey: Keys.sortOrder),
           let value = TextureSortOrder(rawValue: raw) {
            sortOrder = value
        }
        if let raw = UserDefaults.standard.string(forKey: Keys.trendRange),
           let value = TrendDateRange(rawValue: raw) {
            trendDateRange = value
        }
        if let raw = UserDefaults.standard.string(forKey: Keys.preferredMetrics),
           let value = PreferredMetric(rawValue: raw) {
            preferredMetrics = value
        }
        lastUsedColorHex = UserDefaults.standard.string(forKey: Keys.lastUsedColor) ?? "FF0090"
        if UserDefaults.standard.object(forKey: Keys.defaultGrain) != nil {
            defaultGrain = UserDefaults.standard.double(forKey: Keys.defaultGrain)
        }
        colorHistory = loadCodable([String].self, key: Keys.colorHistory) ?? [lastUsedColorHex]
        achievements = loadCodable([Achievement].self, key: Keys.achievements) ?? AchievementCatalog.all
        itemsCreated = UserDefaults.standard.integer(forKey: Keys.itemsCreated)
        streakDays = UserDefaults.standard.integer(forKey: Keys.streak)
        totalSessionsCompleted = UserDefaults.standard.integer(forKey: Keys.sessions)
        totalMinutesUsed = UserDefaults.standard.integer(forKey: Keys.minutes)
        beginSession()
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        HapticService.success()
    }

    func beginSession() {
        sessionStartedAt = Date()
        updateStreak()
    }

    func endSessionIfNeeded() {
        guard let start = sessionStartedAt else { return }
        let minutes = max(1, Int(Date().timeIntervalSince(start) / 60))
        totalMinutesUsed += minutes
        totalSessionsCompleted += 1
        sessionStartedAt = Date()
        recordAnalytics(kind: "session", categoryId: "custom", textureId: nil, value: Double(minutes))
        evaluateAchievements()
    }

    func markSessionActivity() {
        totalSessionsCompleted += 1
        totalMinutesUsed += 1
        updateStreak()
        evaluateAchievements()
    }

    private func updateStreak() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if lastActiveDay == today { return }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            let y = formatter.string(from: yesterday)
            if lastActiveDay == y {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        lastActiveDay = today
    }

    var lastUsedColor: Color {
        get { Color(hex: lastUsedColorHex) }
        set { lastUsedColorHex = newValue.toHexString() }
    }

    var sortedTextures: [TextureItem] {
        switch sortOrder {
        case .newest:
            return textures.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return textures.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .usage:
            return textures.sorted { $0.usageCount > $1.usageCount }
        case .category:
            return textures.sorted {
                categoryName(for: $0.categoryId).localizedCaseInsensitiveCompare(categoryName(for: $1.categoryId)) == .orderedAscending
            }
        case .favorites:
            return textures.filter(\.isFavorite).sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func categoryName(for id: String) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Custom"
    }

    func saveTexture(_ item: TextureItem, isNew: Bool) {
        var copy = item
        copy.updatedAt = Date()
        if let idx = textures.firstIndex(where: { $0.id == copy.id }) {
            textures[idx] = copy
        } else {
            textures.insert(copy, at: 0)
            itemsCreated += 1
            recordAnalytics(kind: "creation", categoryId: copy.categoryId, textureId: copy.id, value: 1)
        }
        lastUsedColorHex = copy.color.toHexString()
        rememberColor(lastUsedColorHex)
        defaultGrain = copy.grain
        upsertPattern(from: copy)
        if isNew {
            markSessionActivity()
        }
        evaluateAchievements()
        flashSuccess()
        showBanner("Texture saved")
        HapticService.medium()
    }

    func applyTexture(_ item: TextureItem) {
        guard let idx = textures.firstIndex(where: { $0.id == item.id }) else {
            var draft = item
            draft.usageCount += 1
            draft.updatedAt = Date()
            saveTexture(draft, isNew: true)
            recordAnalytics(kind: "apply", categoryId: draft.categoryId, textureId: draft.id, value: 1)
            return
        }
        textures[idx].usageCount += 1
        textures[idx].updatedAt = Date()
        lastUsedColorHex = textures[idx].color.toHexString()
        rememberColor(lastUsedColorHex)
        defaultGrain = textures[idx].grain
        recordAnalytics(kind: "apply", categoryId: textures[idx].categoryId, textureId: textures[idx].id, value: 1)
        markSessionActivity()
        evaluateAchievements()
        flashSuccess()
        showBanner("Texture applied")
        HapticService.success()
    }

    func deleteTexture(_ item: TextureItem) {
        textures.removeAll { $0.id == item.id }
        HapticService.warning()
    }

    func renameTexture(_ item: TextureItem, to name: String) {
        guard let idx = textures.firstIndex(where: { $0.id == item.id }) else { return }
        textures[idx].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        textures[idx].updatedAt = Date()
        HapticService.light()
    }

    func toggleFavorite(_ item: TextureItem) {
        guard let idx = textures.firstIndex(where: { $0.id == item.id }) else { return }
        textures[idx].isFavorite.toggle()
        textures[idx].updatedAt = Date()
        HapticService.light()
        showBanner(textures[idx].isFavorite ? "Added to favorites" : "Removed from favorites")
    }

    func updateTags(_ item: TextureItem, tags: [String]) {
        guard let idx = textures.firstIndex(where: { $0.id == item.id }) else { return }
        let cleaned = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        textures[idx].tags = Array(Set(cleaned)).sorted()
        textures[idx].updatedAt = Date()
        HapticService.light()
    }

    @discardableResult
    func duplicateTexture(_ item: TextureItem) -> TextureItem {
        let copy = item.duplicated()
        textures.insert(copy, at: 0)
        itemsCreated += 1
        recordAnalytics(kind: "creation", categoryId: copy.categoryId, textureId: copy.id, value: 1)
        evaluateAchievements()
        showBanner("Texture duplicated")
        HapticService.success()
        return copy
    }

    func rememberColor(_ hex: String) {
        var next = colorHistory.filter { $0.caseInsensitiveCompare(hex) != .orderedSame }
        next.insert(hex.uppercased(), at: 0)
        colorHistory = Array(next.prefix(12))
    }

    func addCategory(name: String, symbol: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let id = "cat_" + UUID().uuidString.prefix(8)
        categories.append(TextureCategory(id: String(id), name: trimmed, symbol: symbol))
        HapticService.success()
        showBanner("Category added")
    }

    func renameCategory(_ category: TextureCategory, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let idx = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[idx].name = trimmed
        HapticService.light()
    }

    func deleteCategory(_ category: TextureCategory) {
        guard categories.count > 1 else { return }
        categories.removeAll { $0.id == category.id }
        for i in textures.indices where textures[i].categoryId == category.id {
            textures[i].categoryId = "custom"
        }
        if categories.contains(where: { $0.id == "custom" }) == false {
            categories.append(TextureCategory(id: "custom", name: "Custom", symbol: "star.fill"))
        }
        HapticService.warning()
    }

    func blendTextures(_ a: TextureItem, _ b: TextureItem, mix: Double) -> TextureItem {
        let t = min(1, max(0, mix))
        let color = Color(
            red: a.red * (1 - t) + b.red * t,
            green: a.green * (1 - t) + b.green * t,
            blue: a.blue * (1 - t) + b.blue * t
        )
        var blended = TextureItem.fresh(
            name: "\(a.name.isEmpty ? "A" : a.name) × \(b.name.isEmpty ? "B" : b.name)",
            color: color,
            grain: a.grain * (1 - t) + b.grain * t,
            opacity: a.opacity * (1 - t) + b.opacity * t,
            patternScale: a.patternScale * (1 - t) + b.patternScale * t,
            patternKind: t < 0.5 ? a.patternKind : b.patternKind,
            categoryId: t < 0.5 ? a.categoryId : b.categoryId,
            tags: Array(Set(a.tags + b.tags + ["blend"])).sorted(),
            patternAngle: a.patternAngle * (1 - t) + b.patternAngle * t,
            patternDensity: a.patternDensity * (1 - t) + b.patternDensity * t,
            patternThickness: a.patternThickness * (1 - t) + b.patternThickness * t
        )
        blended.isFavorite = false
        return blended
    }

    func similarTextures(to item: TextureItem, limit: Int = 6) -> [TextureItem] {
        textures
            .filter { $0.id != item.id }
            .map { candidate -> (TextureItem, Double) in
                var score = 0.0
                if candidate.patternKind == item.patternKind { score += 3 }
                if candidate.categoryId == item.categoryId { score += 2 }
                score += 1.5 - min(1.5, abs(candidate.grain - item.grain) * 3)
                score += 1.0 - min(1.0, abs(candidate.patternScale - item.patternScale) * 2)
                let colorDist = abs(candidate.red - item.red) + abs(candidate.green - item.green) + abs(candidate.blue - item.blue)
                score += max(0, 1.5 - colorDist)
                let sharedTags = Set(candidate.tags).intersection(item.tags).count
                score += Double(sharedTags) * 0.75
                return (candidate, score)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    func upsertPattern(from item: TextureItem) {
        let pattern = UserPattern(
            id: UUID(),
            name: item.name.isEmpty ? item.patternKind.title : item.name,
            patternKind: item.patternKind,
            patternScale: item.patternScale,
            grain: item.grain,
            createdAt: Date()
        )
        if let existing = userPatterns.firstIndex(where: {
            $0.patternKind == pattern.patternKind && abs($0.patternScale - pattern.patternScale) < 0.01
        }) {
            userPatterns[existing] = pattern
        } else {
            userPatterns.insert(pattern, at: 0)
            if userPatterns.count > 40 {
                userPatterns = Array(userPatterns.prefix(40))
            }
        }
    }

    func recordAnalytics(kind: String, categoryId: String, textureId: UUID?, value: Double) {
        let event = TextureAnalyticsEvent(
            id: UUID(),
            textureId: textureId,
            categoryId: categoryId,
            kind: kind,
            value: value,
            date: Date()
        )
        textureAnalytics.insert(event, at: 0)
        if textureAnalytics.count > 500 {
            textureAnalytics = Array(textureAnalytics.prefix(500))
        }
    }

    func filteredAnalytics() -> [TextureAnalyticsEvent] {
        guard let start = trendDateRange.startDate else { return textureAnalytics }
        return textureAnalytics.filter { $0.date >= start }
    }

    func metricSeries() -> [(label: String, value: Double)] {
        let events = filteredAnalytics()
        switch preferredMetrics {
        case .usage:
            let applies = events.filter { $0.kind == "apply" }
            return groupByDay(applies)
        case .popularity:
            var totals: [String: Double] = [:]
            for event in events where event.kind == "apply" || event.kind == "creation" {
                totals[event.categoryId, default: 0] += event.value
            }
            return categories.map { cat in
                (cat.name, totals[cat.id, default: 0])
            }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        case .creations:
            let creations = events.filter { $0.kind == "creation" }
            return groupByDay(creations)
        }
    }

    private func groupByDay(_ events: [TextureAnalyticsEvent]) -> [(label: String, value: Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        var buckets: [String: Double] = [:]
        var order: [String] = []
        for event in events.sorted(by: { $0.date < $1.date }) {
            let key = formatter.string(from: event.date)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: 0] += event.value
        }
        return order.map { ($0, buckets[$0] ?? 0) }
    }

    @discardableResult
    func evaluateAchievements() -> [Achievement] {
        let result = AchievementCatalog.evaluate(
            itemsCreated: itemsCreated,
            sessionsCompleted: totalSessionsCompleted,
            existing: achievements
        )
        achievements = result.updated
        if let first = result.newlyUnlocked.first {
            showBanner(first.title)
            HapticService.success()
        }
        return result.newlyUnlocked
    }

    func resetAll() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        UserDefaults.standard.removePersistentDomain(forName: domain)
        hasSeenOnboarding = false
        textures = []
        categories = TextureCategory.defaults
        userPatterns = []
        textureAnalytics = []
        sortOrder = .newest
        trendDateRange = .week7
        preferredMetrics = .usage
        lastUsedColorHex = "FF0090"
        defaultGrain = 0.35
        colorHistory = ["FF0090"]
        achievements = AchievementCatalog.all
        itemsCreated = 0
        streakDays = 0
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        bannerTitle = nil
        showSuccessFlash = false
        selectedTab = 0
        NotificationCenter.default.post(name: .dataReset, object: nil)
        objectWillChange.send()
    }

    func flashSuccess() {
        showSuccessFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccessFlash = false
        }
    }

    func showBanner(_ title: String) {
        bannerTitle = title
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            if self?.bannerTitle == title { self?.bannerTitle = nil }
        }
    }

    private func saveCodable<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCodable<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
