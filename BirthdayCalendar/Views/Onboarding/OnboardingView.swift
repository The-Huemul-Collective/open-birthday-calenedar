import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var themeManager: ThemeManager
    var onComplete: (() -> Void)? = nil
    @State private var page: Int = 0

    var theme: any AppTheme { themeManager.current }

    var body: some View {
        ZStack {
            backgroundView

            TabView(selection: $page) {
                freePage.tag(0)
                permissionsPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .ignoresSafeArea()
    }

    // MARK: - Pages

    private var freePage: some View {
        VStack(spacing: BPSpacing.xl) {
            Spacer()

            Text("🎂")
                .font(.system(size: 80))

            Text("Open Birthday")
                .font(BPFont.displayLarge())
                .foregroundStyle(theme.textPrimary)

            VStack(spacing: BPSpacing.md) {
                Text(L10n.Onboarding.freePitch)
                    .font(BPFont.displayMedium())
                    .foregroundStyle(theme.accent)

                Text(L10n.Onboarding.freeSubtitle)
                    .font(BPFont.bodyLarge())
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BPSpacing.xl)
            }

            Spacer()

            Button {
                withAnimation { page = 1 }
            } label: {
                Text(L10n.Onboarding.getStarted)
                    .font(BPFont.titleMedium(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BPSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: BPRadius.xl)
                            .fill(theme.accent)
                    )
                    .padding(.horizontal, BPSpacing.xl)
            }

            Spacer(minLength: BPSpacing.xxxl)
        }
    }

    private var permissionsPage: some View {
        VStack(spacing: BPSpacing.xl) {
            Spacer()

            Text(L10n.Onboarding.permissionsTitle)
                .font(BPFont.displayMedium())
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BPSpacing.xl)

            VStack(spacing: BPSpacing.md) {
                permissionRow(
                    icon: "person.crop.circle",
                    title: L10n.Onboarding.contactsTitle,
                    subtitle: L10n.Onboarding.contactsSubtitle
                )
                permissionRow(
                    icon: "bell.badge",
                    title: L10n.Onboarding.notifTitle,
                    subtitle: L10n.Onboarding.notifSubtitle
                )
            }
            .padding(.horizontal, BPSpacing.lg)

            Spacer()

            Button {
                Task { await requestPermissions() }
            } label: {
                Text(L10n.Onboarding.allowAndContinue)
                    .font(BPFont.titleMedium(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BPSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: BPRadius.xl)
                            .fill(theme.accent)
                    )
                    .padding(.horizontal, BPSpacing.xl)
            }

            Button(L10n.Onboarding.skipForNow) {
                onComplete?()
            }
            .font(BPFont.bodyMedium())
            .foregroundStyle(theme.textSecondary)

            Spacer(minLength: BPSpacing.xxxl)
        }
    }

    // MARK: - Helpers

    private func permissionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: BPSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(theme.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                Text(title)
                    .font(BPFont.titleMedium())
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(BPFont.bodyMedium())
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(BPSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BPRadius.lg)
                .fill(theme.cardBackground)
        )
    }

    @ViewBuilder
    private var backgroundView: some View {
        Rectangle()
            .fill(theme.backgroundPrimary)
            .ignoresSafeArea()
    }

    private func requestPermissions() async {
        _ = try? await ContactsService.shared.requestAccess()
        _ = try? await NotificationService.shared.requestAuthorization()
        onComplete?()
    }
}
