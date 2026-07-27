import SwiftUI

struct SoftCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        content()
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color("AppSurface"), Color("AppSurface").opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color("AppAccent").opacity(0.45), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color("AppPrimary"),
                            Color("AppAccent").opacity(0.92),
                            Color("AppPrimary").opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Canvas { context, size in
                        let spacing: CGFloat = 5
                        var path = Path()
                        var x: CGFloat = -size.height
                        while x < size.width + size.height {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                            x += spacing
                        }
                        context.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1)
                    }
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.clear,
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color("AppAccent").opacity(0.35),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color("AppPrimary").opacity(0.4), radius: configuration.isPressed ? 4 : 12, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeInOut(duration: 0.22), value: configuration.isPressed)
    }
}

struct AchievementBanner: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(Color("AppPrimary"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color("AppSurface"), Color("AppBackground")], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 58))
                .foregroundStyle(Color("AppPrimary"))
                .shadow(color: Color("AppPrimary").opacity(0.45), radius: 14)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(actionTitle) {
                HapticService.light()
                action()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BannerImageCard: View {
    var imageName: String = "img_banner"
    var height: CGFloat = 120

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
            )
    }
}

struct AccentButtonImage: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.light()
            action()
        }) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
