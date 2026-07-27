import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0

    private let pages: [(image: String, title: String, detail: String, symbol: String)] = [
        (
            "img_background",
            "Create Textures",
            "Develop intricate textures with customizable controls.",
            "scribble.variable"
        ),
        (
            "img_banner",
            "Organize Library",
            "Store and edit your textures using an intuitive library system.",
            "paintbrush"
        ),
        (
            "img_accent",
            "Start Creating",
            "Begin by designing your first custom texture now.",
            "chart.bar.fill"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.35), value: page)

            VStack(spacing: 12) {
                if page < pages.count - 1 {
                    Button("Continue") {
                        HapticService.light()
                        withAnimation { page += 1 }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Skip") {
                        store.completeOnboarding()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(minHeight: 44)
                } else {
                    Button("Get Started") {
                        store.completeOnboarding()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .padding(.top, 8)
        }
        .screenBackground()
    }

    private func onboardingPage(_ item: (image: String, title: String, detail: String, symbol: String)) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)

            Image(item.image)
                .resizable()
                .scaledToFill()
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color("AppPrimary").opacity(0.35), radius: 18, y: 10)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: item.symbol)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white)
                        .padding(12)
                        .background(Color("AppPrimary"))
                        .clipShape(Circle())
                        .shadow(color: Color("AppPrimary").opacity(0.5), radius: 8, y: 4)
                        .offset(x: 8, y: 8)
                }

            Text(item.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)

            Text(item.detail)
                .font(.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}
