import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false
    @AppStorage("app_sound_enabled") private var soundEnabled = true
    @AppStorage("app_haptics_enabled") private var hapticsEnabled = true
    @AppStorage("reminder_enabled") private var reminderEnabled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Textures: \(store.itemsCreated)")
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("Sessions: \(store.totalSessionsCompleted)")
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("Minutes: \(store.totalMinutesUsed)")
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("Streak: \(store.streakDays) days")
                                .foregroundStyle(Color("AppTextSecondary"))

                            NavigationLink {
                                StatsView()
                            } label: {
                                HStack {
                                    Text("View Statistics")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color("AppPrimary"))
                                .padding(.top, 6)
                            }

                            NavigationLink {
                                CategoriesManageView()
                            } label: {
                                HStack {
                                    Text("Manage Categories")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color("AppPrimary"))
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $soundEnabled) {
                                Label("Sound Effects", systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .onChange(of: soundEnabled) { value in
                                HapticService.soundEnabled = value
                                if value {
                                    HapticService.play(.click)
                                }
                                if NotificationService.reminderEnabled {
                                    NotificationService.scheduleReminder()
                                }
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            Toggle(isOn: $hapticsEnabled) {
                                Label("Haptic Feedback", systemImage: "hand.tap.fill")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .onChange(of: hapticsEnabled) { value in
                                HapticService.hapticsEnabled = value
                                if value {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            Toggle(isOn: $reminderEnabled) {
                                Label("Daily Reminder", systemImage: "bell.fill")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .onChange(of: reminderEnabled) { value in
                                NotificationService.reminderEnabled = value
                                if value {
                                    HapticService.success()
                                } else {
                                    HapticService.light()
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            settingsButton(title: "Rate Us", systemImage: "star.fill") { rateApp() }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") { openURL(AppLinks.privacyPolicy) }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") { openURL(AppLinks.termsOfUse) }
                        }
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data").lineLimit(1).minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onAppear {
                HapticService.soundEnabled = soundEnabled
                HapticService.hapticsEnabled = hapticsEnabled
                reminderEnabled = NotificationService.reminderEnabled
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { store.resetAll() }
            } message: {
                Text("This clears all locally stored data on this device.")
            }
        }
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage).foregroundStyle(Color("AppPrimary")).frame(width: 28)
                Text(title).foregroundStyle(Color("AppTextPrimary")).lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
