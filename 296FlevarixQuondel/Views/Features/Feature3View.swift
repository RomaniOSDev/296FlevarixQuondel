import SwiftUI

struct Feature3View: View {
    @EnvironmentObject private var store: AppDataStore

    private var series: [(label: String, value: Double)] {
        store.metricSeries()
    }

    var body: some View {
        Group {
            if store.textureAnalytics.isEmpty && store.textures.isEmpty {
                EmptyStateView(
                    symbol: "chart.bar.fill",
                    title: "No Trend Data",
                    message: "Usage and popularity charts appear after you create and apply textures.",
                    actionTitle: "Create Texture"
                ) {
                    store.selectedTab = 0
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Insight Controls")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Picker("Range", selection: $store.trendDateRange) {
                                    ForEach(TrendDateRange.allCases) { range in
                                        Text(range.title).tag(range)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Picker("Metric", selection: $store.preferredMetrics) {
                                    ForEach(PreferredMetric.allCases) { metric in
                                        Text(metric.title).tag(metric)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color("AppPrimary"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(store.preferredMetrics.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))

                                if series.isEmpty {
                                    Text("No events in this range yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
                                } else {
                                    TrendChartCanvas(points: series)
                                        .frame(height: 220)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        SoftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Category Popularity")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))

                                let popularity = categoryPopularity()
                                if popularity.isEmpty {
                                    Text("Apply textures to build category trends.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                } else {
                                    ForEach(popularity, id: \.label) { row in
                                        HStack {
                                            Text(row.label)
                                                .foregroundStyle(Color("AppTextPrimary"))
                                                .lineLimit(1)
                                            Spacer()
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule().fill(Color("AppBackground").opacity(0.5))
                                                    Capsule()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                        .frame(width: max(8, geo.size.width * row.ratio))
                                                }
                                            }
                                            .frame(width: 120, height: 10)
                                            Text("\(Int(row.value))")
                                                .font(.caption.monospacedDigit())
                                                .foregroundStyle(Color("AppTextSecondary"))
                                                .frame(width: 28, alignment: .trailing)
                                        }
                                        .frame(minHeight: 28)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        SoftCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Local Analytics")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Events: \(store.filteredAnalytics().count)")
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text("Textures: \(store.textures.count)")
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text("Total applies: \(store.textures.reduce(0) { $0 + $1.usageCount })")
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func categoryPopularity() -> [(label: String, value: Double, ratio: Double)] {
        var totals: [String: Double] = [:]
        for event in store.filteredAnalytics() where event.kind == "apply" || event.kind == "creation" {
            totals[event.categoryId, default: 0] += event.value
        }
        let maxValue = max(totals.values.max() ?? 1, 1)
        return store.categories.compactMap { cat in
            let value = totals[cat.id, default: 0]
            guard value > 0 else { return nil }
            return (cat.name, value, value / maxValue)
        }.sorted { $0.value > $1.value }
    }
}

struct TrendChartCanvas: View {
    let points: [(label: String, value: Double)]

    var body: some View {
        VStack(spacing: 8) {
            Canvas { context, size in
                let maxValue = max(points.map(\.value).max() ?? 1, 1)
                let count = max(points.count, 1)
                let gap: CGFloat = 8
                let barWidth = max(10, (size.width - gap * CGFloat(count + 1)) / CGFloat(count))

                var baseline = Path()
                baseline.move(to: CGPoint(x: 0, y: size.height - 2))
                baseline.addLine(to: CGPoint(x: size.width, y: size.height - 2))
                context.stroke(baseline, with: .color(Color("AppTextSecondary").opacity(0.35)), lineWidth: 1)

                for (index, point) in points.enumerated() {
                    let height = CGFloat(point.value / maxValue) * (size.height - 8)
                    let x = gap + CGFloat(index) * (barWidth + gap)
                    let y = size.height - height
                    let rect = CGRect(x: x, y: y, width: barWidth, height: max(4, height))
                    let path = Path(roundedRect: rect, cornerRadius: 6)
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [Color("AppPrimary"), Color("AppAccent")]),
                            startPoint: CGPoint(x: rect.midX, y: rect.minY),
                            endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Text(point.label)
                        .font(.system(size: 9))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
