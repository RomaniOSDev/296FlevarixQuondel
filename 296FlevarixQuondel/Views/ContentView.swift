import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if store.hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }

            if let title = store.bannerTitle {
                AchievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(2)
            }

            if store.showSuccessFlash {
                Color("AppPrimary").opacity(0.12)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: store.bannerTitle)
        .animation(.easeInOut(duration: 0.25), value: store.showSuccessFlash)
        .preferredColorScheme(.dark)
        .environmentObject(store)
    }
}
