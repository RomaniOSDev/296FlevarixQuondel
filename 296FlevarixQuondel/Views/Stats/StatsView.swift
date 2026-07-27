import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var range: TrendDateRange = .week7

    private var events: [TextureAnalyticsEvent] {
        guard let start = range.startDate else { return store.textureAnalytics }
        return store.textureAnalytics.filter { $0.date >= start }
    }

    private var activitySeries: [DayPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        var buckets: [String: (creations: Double, applies: Double)] = [:]
        var order: [String] = []
        for event in events.sorted(by: { $0.date < $1.date }) {
            let key = formatter.string(from: event.date)
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = (0, 0)
            }
            if event.kind == "creation" {
                buckets[key]?.creations += event.value
            } else if event.kind == "apply" {
                buckets[key]?.applies += event.value
            }
        }
        return order.flatMap { day -> [DayPoint] in
            let values = buckets[day] ?? (0, 0)
            return [
                DayPoint(day: day, metric: "Created", value: values.creations),
                DayPoint(day: day, metric: "Applied", value: values.applies)
            ]
        }
    }

    private var categorySeries: [NamedValue] {
        var totals: [String: Double] = [:]
        for event in events where event.kind == "apply" || event.kind == "creation" {
            totals[event.categoryId, default: 0] += event.value
        }
        return store.categories.compactMap { cat in
            let value = totals[cat.id, default: 0]
            guard value > 0 else { return nil }
            return NamedValue(name: cat.name, value: value)
        }
        .sorted { $0.value > $1.value }
    }

    private var patternSeries: [NamedValue] {
        var totals: [String: Double] = [:]
        for texture in store.textures {
            totals[texture.patternKind.title, default: 0] += 1
        }
        return totals
            .map { NamedValue(name: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private var unlockedCount: Int {
        store.achievements.filter(\.isUnlocked).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            metricTile("Textures", "\(store.itemsCreated)", "paintbrush.pointed.fill")
                            metricTile("Sessions", "\(store.totalSessionsCompleted)", "clock.fill")
                            metricTile("Minutes", "\(store.totalMinutesUsed)", "timer")
                            metricTile("Streak", "\(store.streakDays)d", "flame.fill")
                            metricTile("Library", "\(store.textures.count)", "square.stack.3d.up.fill")
                            metricTile("Patterns", "\(store.userPatterns.count)", "circle.grid.3x3.fill")
                        }

                        Picker("Range", selection: $range) {
                            ForEach(TrendDateRange.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        if activitySeries.allSatisfy({ $0.value == 0 }) {
                            emptyChart("Create or apply textures to see activity.")
                        } else {
                            Chart(activitySeries) { point in
                                BarMark(
                                    x: .value("Day", point.day),
                                    y: .value("Count", point.value)
                                )
                                .foregroundStyle(by: .value("Metric", point.metric))
                                .position(by: .value("Metric", point.metric))
                            }
                            .chartForegroundStyleScale([
                                "Created": Color("AppPrimary"),
                                "Applied": Color("AppAccent")
                            ])
                            .chartLegend(position: .bottom, alignment: .center)
                            .frame(height: 220)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        if categorySeries.isEmpty {
                            emptyChart("Category usage appears after you craft.")
                        } else {
                            Chart(categorySeries) { item in
                                BarMark(
                                    x: .value("Count", item.value),
                                    y: .value("Category", item.name)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AppAccent"), Color("AppPrimary")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(6)
                            }
                            .frame(height: max(160, CGFloat(categorySeries.count) * 34))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pattern Mix")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        if patternSeries.isEmpty {
                            emptyChart("Saved textures will show pattern distribution.")
                        } else {
                            Chart(patternSeries) { item in
                                BarMark(
                                    x: .value("Count", item.value),
                                    y: .value("Pattern", item.name)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AppPrimary"), Color("AppAccent")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(6)
                            }
                            .frame(height: max(160, CGFloat(patternSeries.count) * 34))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Achievements")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        HStack(alignment: .center, spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color("AppBackground").opacity(0.7), lineWidth: 10)
                                Circle()
                                    .trim(from: 0, to: store.achievements.isEmpty ? 0 : CGFloat(unlockedCount) / CGFloat(store.achievements.count))
                                    .stroke(
                                        AngularGradient(
                                            colors: [Color("AppPrimary"), Color("AppAccent"), Color("AppPrimary")],
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 2) {
                                    Text("\(unlockedCount)")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Text("/ \(store.achievements.count)")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(width: 96, height: 96)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(unlockedCount) unlocked")
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .font(.subheadline.weight(.semibold))
                                Text("Keep crafting to unlock the rest of the collection.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
    }

    private func metricTile(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color("AppBackground").opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func emptyChart(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
            .multilineTextAlignment(.center)
    }
}

private struct DayPoint: Identifiable {
    var id: String { "\(day)-\(metric)" }
    let day: String
    let metric: String
    let value: Double
}

private struct NamedValue: Identifiable {
    var id: String { name }
    let name: String
    let value: Double
}
