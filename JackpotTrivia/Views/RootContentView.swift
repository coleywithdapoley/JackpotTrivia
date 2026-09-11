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
    @State private var hasPassedInviteGate = false
    @State private var hasAppAccess = LocalAppAccessService.shared.hasAppAccess
    @State private var firstRunPhase: FirstRunPhase = .quickHitIntro

    var body: some View {
        Group {
            switch firstRunPhase {
            case .quickHitIntro:
                QuickHitIntroView(
                    onPlaySample: startQuickHit,
                    onSignIn: { firstRunPhase = .auth(showSignUp: false) }
                )

            case .quickHitPlaying:
                guestTriviaStack

            case .quickHitResults:
                QuickHitResultsView(
                    onCreateAccount: { firstRunPhase = .auth(showSignUp: true) },
                    onSignIn: { firstRunPhase = .auth(showSignUp: false) }
                )

            case .auth(let showSignUp):
                AuthGateView(initialShowSignUp: showSignUp)

            case .appAccessGate:
                appAccessFlow

            case .firstJackpotPlaying:
                firstJackpotStack

            case .home:
                authenticatedHub
            }
        }
        .environmentObject(gameSession)
        .environment(\.analytics, analytics)
        .environment(\.featureGates, featureGates)
        .tint(AppColors.brandPrimary)
        .onAppear {
            analytics.track(.appOpened)
            syncInviteGateFromPersistence()
            syncFirstRunPhase()
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                syncInviteGateFromPersistence()
                handleAuthenticatedEntry()
            } else {
                resetSessionOnSignOut()
                syncFirstRunPhase()
            }
        }
        .onChange(of: auth.currentUser?.id) { _, _ in
            if auth.isAuthenticated {
                syncInviteGateFromPersistence()
                handleAuthenticatedEntry()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .premiumAccessDidChange)) { _ in
            featureGates = FeatureGates.current
        }
        .onReceive(NotificationCenter.default.publisher(for: .membershipDidChange)) { _ in
            auth.refreshMembershipTier()
        }
    }

    // MARK: - Phase resolution

    private func syncFirstRunPhase() {
        hasAppAccess = appAccess.hasAppAccess
        guard !auth.isAuthenticated else {
            handleAuthenticatedEntry()
            return
        }

        switch firstRunPhase {
        case .quickHitPlaying, .quickHitResults, .auth:
            return
        default:
            firstRunPhase = OnboardingStore.hasCompletedQuickHit
                ? .auth(showSignUp: false)
                : .quickHitIntro
        }
    }

    private func handleAuthenticatedEntry() {
        hasAppAccess = appAccess.hasAppAccess

        if AppConfig.requireAppAccessCode && !hasAppAccess {
            firstRunPhase = .appAccessGate
            return
        }

        // Invite gates hub and first jackpot until resolved (in-session or persisted member).
        if AppConfig.requiresInviteAfterAuth && !isInviteGateResolved {
            firstRunPhase = .home
            return
        }

        if needsFirstJackpot(for: auth.currentUser?.id) {
            if firstRunPhase != .firstJackpotPlaying {
                startFirstJackpot()
            }
            return
        }

        firstRunPhase = .home
    }

    /// True when invite-only launch is satisfied for this installation.
    private var isInviteGateResolved: Bool {
        guard AppConfig.requiresInviteAfterAuth else { return true }
        return hasPassedInviteGate || InviteLinkService.currentMemberID != nil
    }

    private func syncInviteGateFromPersistence() {
        if InviteLinkService.currentMemberID != nil {
            hasPassedInviteGate = true
        }
    }

    private func resetSessionOnSignOut() {
        gameSession.clearRound()
        navigationPath = NavigationPath()
        hasPassedInviteGate = false
    }

    private func needsFirstJackpot(for userID: String?) -> Bool {
        guard let userID else { return false }
        return !OnboardingStore.hasCompletedWarmup(for: userID)
    }

    // MARK: - Guest Quick Hit

    private func startQuickHit() {
        gameSession.beginQuickHitRound()
        firstRunPhase = .quickHitPlaying
    }

    private var guestTriviaStack: some View {
        NavigationStack {
            TriviaQuestionView(
                onSessionComplete: {
                    firstRunPhase = .quickHitResults
                },
                onBackToCategories: {
                    gameSession.clearRound()
                    firstRunPhase = .quickHitIntro
                }
            )
            .navigationTitle(AppConfig.Copy.quickHitTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - App access (beta — after account, not before Quick Hit)

    private var appAccessFlow: some View {
        NavigationStack {
            AppAccessCodeView {
                hasAppAccess = true
                handleAuthenticatedEntry()
            }
        }
    }

    // MARK: - First Detroit Jackpot

    private func startFirstJackpot() {
        gameSession.beginDailyRound()
        featureGates.applyQuestionLimit(to: gameSession)
        navigationPath = NavigationPath()
        firstRunPhase = .firstJackpotPlaying
    }

    private var firstJackpotStack: some View {
        NavigationStack(path: $navigationPath) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .brandScreenBackground()
                .onAppear {
                    guard navigationPath.isEmpty else { return }
                    navigationPath.append(AppRoute.trivia)
                }
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    // MARK: - Signed-in hub

    private var authenticatedHub: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if AppConfig.requiresInviteAfterAuth && !isInviteGateResolved {
                    InviteAccessView {
                        hasPassedInviteGate = true
                        handleAuthenticatedEntry()
                    }
                    .navigationTitle("Join")
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
                                .font(.footnote)
                                .foregroundStyle(AppColors.textTertiary)
                                .accessibilityLabel("Admin access settings")
                        }
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
    }

    private var showAdminGear: Bool {
        auth.isAdmin && (!AppConfig.requiresInviteAfterAuth || isInviteGateResolved)
    }

    private func startDailyTrivia() {
        analytics.track(.dailyStarted)
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
            if auth.isAdmin {
                AddQuestionView()
            } else {
                adminOnlyPlaceholder
            }

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
                        if firstRunPhase == .firstJackpotPlaying {
                            firstRunPhase = .home
                        }
                        return
                    }
                    featureGates.applyQuestionLimit(to: gameSession)
                    navigationPath.removeLast()
                },
                onChooseCategories: {
                    let wasPractice = gameSession.roundKind == .practice
                    gameSession.clearRound()
                    popToHome()
                    if wasPractice {
                        navigationPath.append(AppRoute.categorySelection)
                    }
                },
                onExit: {
                    gameSession.clearRound()
                    navigationPath = NavigationPath()
                    if firstRunPhase == .firstJackpotPlaying {
                        firstRunPhase = .home
                    }
                }
            )
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var adminOnlyPlaceholder: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Admin only")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)
            Text("This screen is limited to founder accounts.")
                .appBodyText()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appScreenHorizontalPadding()
        .padding(.top, AppSpacing.section)
        .brandScreenBackground()
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func popToHome() {
        navigationPath = NavigationPath()
    }

    private var triviaNavigationTitle: String {
        switch gameSession.roundKind {
        case .dailyJackpot:
            if needsFirstJackpot(for: auth.currentUser?.id) {
                return AppConfig.Copy.firstJackpotTitle
            }
            return "Daily Jackpot"
        case .privateLounge: return "Private Lounge"
        case .onboardingWarmup: return "Warmup"
        case .quickHitSample: return AppConfig.Copy.quickHitTitle
        case .practice: return "Trivia"
        }
    }
}

// MARK: - Auth gate (post–Quick Hit)

private struct AuthGateView: View {
    let initialShowSignUp: Bool

    @State private var showSignUp: Bool
    @State private var showForgotPassword = false

    init(initialShowSignUp: Bool) {
        self.initialShowSignUp = initialShowSignUp
        _showSignUp = State(initialValue: initialShowSignUp)
    }

    var body: some View {
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
        .onChange(of: initialShowSignUp) { _, value in
            if value { showSignUp = true }
        }
    }
}

#Preview {
    RootContentView()
        .environmentObject(AuthManager.shared)
}
