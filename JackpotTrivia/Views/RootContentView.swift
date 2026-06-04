//
//  RootContentView.swift
//  JackpotTrivia
//

import SwiftUI

struct RootContentView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var gameSession = GameSession()
    @State private var navigationPath = NavigationPath()

    private let analytics: AnalyticsTracking = ConsoleAnalyticsService()
    private let appAccess: AppAccessServiceProtocol = LocalAppAccessService.shared
    @State private var featureGates = FeatureGates.current
    @State private var showPremiumUpgrade = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var hasPassedInviteGate = false
    @State private var hasAppAccess = LocalAppAccessService.shared.hasAppAccess
    @State private var needsWarmup = false

    var body: some View {
        Group {
            if AppConfig.requireAppAccessCode && !hasAppAccess {
                appAccessFlow
            } else if auth.isAuthenticated {
                authenticatedFlow
            } else {
                unauthenticatedFlow
            }
        }
        .environmentObject(gameSession)
        .environment(\.analytics, analytics)
        .environment(\.featureGates, featureGates)
        .tint(AppColors.brandGreen)
        .onAppear {
            analytics.track(.appOpened)
            refreshSessionFlags()
        }
        .onChange(of: auth.currentUser?.id) { _, _ in
            refreshSessionFlags()
        }
        .onReceive(NotificationCenter.default.publisher(for: .premiumAccessDidChange)) { _ in
            featureGates = FeatureGates.current
        }
        .onReceive(NotificationCenter.default.publisher(for: .membershipDidChange)) { _ in
            auth.refreshMembershipTier()
        }
    }

    private func refreshSessionFlags() {
        hasAppAccess = appAccess.hasAppAccess
        if let userID = auth.currentUser?.id {
            needsWarmup = !OnboardingStore.hasCompletedWarmup(for: userID)
        } else {
            needsWarmup = false
        }
    }

  // MARK: - App access gate

    private var appAccessFlow: some View {
        NavigationStack {
            AppAccessCodeView {
                hasAppAccess = true
            }
        }
    }

  // MARK: - Auth gate

    private var unauthenticatedFlow: some View {
        NavigationStack {
            AuthSignInView(
                onSignUp: { showSignUp = true },
                onForgotPassword: { showForgotPassword = true }
            )
            .navigationDestination(isPresented: $showSignUp) {
                AuthSignUpView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

  // MARK: - Signed-in flow

    private var authenticatedFlow: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if AppConfig.requiresInviteAfterAuth && !hasPassedInviteGate {
                    InviteAccessView {
                        hasPassedInviteGate = true
                    }
                    .navigationTitle("Join")
                } else if needsWarmup {
                    warmupPrompt
                } else {
                    DailyJackpotView(
                        onPlayDaily: startDailyTrivia,
                        onPractice: startPractice,
                        onInviteJoin: { hasPassedInviteGate = false },
                        onLeaderboard: { navigationPath.append(AppRoute.leaderboard) },
                        onPrivateLounge: { navigationPath.append(AppRoute.privateLounge) },
                        onMembership: { navigationPath.append(AppRoute.membership) }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showAdminGear {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            AdminAccessSettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .accessibilityLabel("Admin access settings")
                        }
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .premiumUpgradeSheet(isPresented: $showPremiumUpgrade)
    }

    private var showAdminGear: Bool {
        (!AppConfig.requiresInviteAfterAuth || hasPassedInviteGate) && !needsWarmup
    }

    private var warmupPrompt: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            Text("Quick warmup")
                .appScreenTitle()
            Text("Answer 5 fast questions to get started. This does not use your official daily jackpot run.")
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)
            Button("Start warmup") {
                startWarmup()
            }
            .buttonStyle(.appPrimary)
        }
        .appScreenHorizontalPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .navigationTitle("Welcome")
    }

    private func startWarmup() {
        featureGates.applyQuestionLimit(to: gameSession)
        gameSession.beginWarmupRound()
        navigationPath.append(AppRoute.trivia)
    }

    private func startDailyTrivia() {
        analytics.track(.dailyStarted)
        featureGates.applyQuestionLimit(to: gameSession)
        navigationPath.append(AppRoute.trivia)
    }

    private func startPractice() {
        analytics.track(.practiceStarted)
        navigationPath.append(AppRoute.categorySelection)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .categorySelection:
            CategorySelectionView {
                featureGates.applyQuestionLimit(to: gameSession)
                navigationPath.append(AppRoute.trivia)
            }
            .navigationTitle("Play")
            .navigationBarTitleDisplayMode(.inline)

        case .comfortPreferences:
            ComfortPreferencesView()

        case .leaderboard:
            LeaderboardView()

        case .membership:
            MembershipView()

        case .privateLounge:
            PrivateLoungeAccessView(
                onPlay: {
                    featureGates.applyQuestionLimit(to: gameSession)
                    navigationPath.append(AppRoute.trivia)
                },
                onEnterLoungeCode: {
                    navigationPath.append(AppRoute.membership)
                }
            )

        case .addQuestion:
            AddQuestionView()

        case .trivia:
            TriviaQuestionView(
                onSessionComplete: {
                    if gameSession.roundKind == .dailyJackpot {
                        analytics.track(.dailyFinished(
                            correct: gameSession.correctAnswers,
                            total: gameSession.totalQuestions
                        ))
                    }
                    navigationPath.append(AppRoute.results)
                },
                onBackToCategories: {
                    popToHome()
                }
            )
            .navigationTitle(triviaNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)

        case .results:
            ResultsView(
                onPlayAgain: {
                    guard gameSession.roundKind != .dailyJackpot || !DailyGameService.hasCompletedDailyToday else {
                        popToHome()
                        return
                    }
                    gameSession.resetForReplay()
                    featureGates.applyQuestionLimit(to: gameSession)
                    navigationPath.removeLast()
                },
                onChooseCategories: {
                    let wasPractice = gameSession.roundKind == .practice
                    gameSession.clearRound()
                    popToHome()
                    refreshSessionFlags()
                    if wasPractice {
                        navigationPath.append(AppRoute.categorySelection)
                    }
                },
                onExit: {
                    gameSession.clearRound()
                    navigationPath = NavigationPath()
                    refreshSessionFlags()
                }
            )
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func popToHome() {
        navigationPath = NavigationPath()
    }

    private var triviaNavigationTitle: String {
        switch gameSession.roundKind {
        case .dailyJackpot: return "Daily Jackpot"
        case .privateLounge: return "Private Lounge"
        case .onboardingWarmup: return "Warmup"
        case .practice: return "Trivia"
        }
    }
}

#Preview {
    RootContentView()
        .environmentObject(AuthManager.shared)
}
