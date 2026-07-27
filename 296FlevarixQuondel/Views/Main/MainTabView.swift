import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            Feature1View()
                .tabItem { Label("Designer", systemImage: "scribble.variable") }
                .tag(0)

            LibraryTrendsView()
                .tabItem { Label("Library+Trends", systemImage: "square.grid.2x2.fill") }
                .tag(1)

            AchievementsView()
                .tabItem { Label("Achievements", systemImage: "trophy.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Color("AppPrimary"))
        .onAppear {
            store.evaluateAchievements()
        }
    }
}
