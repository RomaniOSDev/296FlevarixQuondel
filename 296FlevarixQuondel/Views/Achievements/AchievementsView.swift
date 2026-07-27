import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var unlockedCount: Int {
        store.achievements.filter(\.isUnlocked).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        HStack(spacing: 14) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color("AppPrimary"))
                                .shadow(color: Color("AppPrimary").opacity(0.45), radius: 10)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Progress")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("\(unlockedCount) of \(store.achievements.count) unlocked")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                ProgressView(value: Double(unlockedCount), total: Double(max(store.achievements.count, 1)))
                                    .tint(Color("AppPrimary"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(store.achievements) { item in
                        SoftCard {
                            HStack(spacing: 14) {
                                Image(systemName: item.symbol)
                                    .font(.title2)
                                    .foregroundStyle(item.isUnlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color("AppBackground").opacity(0.55))
                                    )
                                    .shadow(color: item.isUnlocked ? Color("AppPrimary").opacity(0.35) : .clear, radius: 8)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(item.detail)
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let date = item.unlockedAt {
                                        Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2)
                                            .foregroundStyle(Color("AppAccent"))
                                    } else {
                                        Text("Locked")
                                            .font(.caption2)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: item.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                                    .foregroundStyle(item.isUnlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .opacity(item.isUnlocked ? 1 : 0.72)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onAppear {
                store.evaluateAchievements()
            }
        }
    }
}
