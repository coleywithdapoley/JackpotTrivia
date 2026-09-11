//
//  TriviaQuestionView.swift
//  JackpotTrivia
//

import SwiftUI

struct TriviaQuestionView: View {
    @EnvironmentObject private var gameSession: GameSession
    @Environment(\.analytics) private var analytics
    @Environment(\.featureGates) private var featureGates
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var onSessionComplete: (() -> Void)?
    var onBackToCategories: () -> Void = {}

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int?
    @State private var sessionComplete = false
    @State private var currentPresentation: PresentedQuestion?
    @State private var timeRemaining: Int = 0
    @State private var timedOut = false
    @State private var lastPointsEarned: Int = 0
    @State private var lastScoreBreakdown: String?
    @State private var showReportSheet = false
    @State private var showReportThanks = false

    private var questions: [TriviaQuestion] {
        gameSession.currentRoundQuestions
    }

    private var questionTotal: Int {
        gameSession.totalQuestions
    }

    private var showsPartyModeNotice: Bool {
        gameSession.playMode == .partyMode && !questions.isEmpty
    }

    private var isLastQuestion: Bool {
        guard !questions.isEmpty else { return true }
        return currentQuestionIndex >= questions.count - 1
    }

    private var hasSelectedAnswer: Bool {
        selectedAnswerIndex != nil
    }

    private var canProceedToNext: Bool {
        hasSelectedAnswer || timedOut
    }

    private var isNextEnabled: Bool {
        canProceedToNext && !sessionComplete && currentPresentation != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if questions.isEmpty {
                emptyRoundView
            } else if let currentPresentation {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if showsPartyModeNotice {
                            partyModeNotice
                                .padding(.top, AppSpacing.screenBottom)
                        }

                        progressSection(presentation: currentPresentation)
                            .padding(.top, showsPartyModeNotice ? AppSpacing.stackItem : AppSpacing.screenBottom)

                        questionSection(text: currentPresentation.question)
                            .padding(.top, AppSpacing.section)

                        answersSection(presentation: currentPresentation)
                            .padding(.top, AppSpacing.section + 4)

                        feedbackSection(presentation: currentPresentation)
                            .padding(.top, AppSpacing.screenBottom)
                    }
                    .appScreenHorizontalPadding()
                    .padding(.bottom, AppSpacing.section)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))

                bottomBar
            } else {
                loadingPlaceholder
            }
        }
        .background {
            ZStack {
                AppColors.brandBackground
                if let presentation = currentPresentation {
                    CategoryTheme.backgroundTint(for: presentation.category)
                }
            }
            .ignoresSafeArea()
        }
        .animation(AppAnimation.quick, value: currentPresentation?.id)
        .onAppear {
            featureGates.applyQuestionLimit(to: gameSession)
            restoreOrStartRound()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            handleAppBackgrounded()
        }
        .onChange(of: currentQuestionIndex) { _, _ in
            loadPresentationForCurrentIndex()
        }
        .task(id: currentPresentation?.id) {
            await runQuestionTimer()
        }
        .sheet(isPresented: $showReportSheet) {
            if let presentation = currentPresentation {
                ReportQuestionSheet(catalogID: presentation.catalogID) {
                    showReportThanks = true
                }
            }
        }
        .alert("Thanks for the feedback", isPresented: $showReportThanks) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We'll review this question.")
        }
    }

    // MARK: - Sections

    private var emptyRoundView: some View {
        VStack(spacing: AppSpacing.section) {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)

            Text(AppConfig.Copy.triviaEmptyTitle)
                .appScreenSubtitle()
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(AppConfig.Copy.triviaEmptyMessage)
                .appBodyText()
                .multilineTextAlignment(.center)

            Button(action: onBackToCategories) {
                Text("Pick Categories")
            }
            .buttonStyle(.appPrimary)
            .accessibilityLabel("Pick Categories")
            .accessibilityHint("Returns to category selection")
        }
        .appScreenHorizontalPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: AppSpacing.stackItem) {
            ProgressView()
                .accessibilityLabel("Loading question")
            Text("Loading question…")
                .appHelperText()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var partyModeNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("Party mode — random questions from every category.")
        }
        .font(.footnote)
        .foregroundStyle(AppColors.brandPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progressSection(presentation: PresentedQuestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if sessionComplete {
                    Text("Session complete")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.brandPrimary)
                } else if questionTotal > 0 {
                    Text("Question \(currentQuestionIndex + 1) of \(questionTotal)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.brandPrimary)
                }

                Spacer()

                if !sessionComplete && selectedAnswerIndex == nil && !timedOut {
                    Label("\(timeRemaining)s", systemImage: "timer")
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(timeRemaining <= 3 ? AppColors.error : AppColors.brandPrimary)
                        .accessibilityLabel("\(timeRemaining) seconds remaining")
                }
            }

            HStack(spacing: 8) {
                CategoryArtwork(category: presentation.category, size: 28, cornerRadius: 6)

                Text(presentation.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)

                Text(presentation.difficulty.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppColors.brandPrimary.opacity(0.12))
                    .foregroundStyle(AppColors.brandPrimary)
                    .clipShape(Capsule())

                Text(presentation.questionType.displayName)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if gameSession.activeMood != .custom, gameSession.roundKind == .practice {
                Text("Mood: \(gameSession.activeMood.displayName)")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if gameSession.currentStreak > 1 {
                Text("Streak: \(gameSession.currentStreak)")
                    .font(.caption2)
                    .foregroundStyle(AppColors.brandPrimary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func questionSection(text: String) -> some View {
        Text(text)
            .appScreenSubtitle()
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Question: \(text)")
    }

    private func answersSection(presentation: PresentedQuestion) -> some View {
        VStack(spacing: AppSpacing.stackItem) {
            ForEach(Array(presentation.answers.enumerated()), id: \.offset) { index, answer in
                answerButton(
                    index: index,
                    text: answer,
                    correctIndex: presentation.correctIndex
                )
            }
        }
        .accessibilityLabel("Answer choices")
    }

    @ViewBuilder
    private func feedbackSection(presentation: PresentedQuestion) -> some View {
        if timedOut, selectedAnswerIndex == nil {
            VStack(alignment: .leading, spacing: 4) {
                Label("Time's up!", systemImage: "clock.badge.exclamationmark")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.error)
                Text("Correct: \(presentation.answers[presentation.correctIndex])")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .accessibilityElement(children: .combine)
        } else if let selectedAnswerIndex {
            let isCorrect = selectedAnswerIndex == presentation.correctIndex
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? AppColors.brandPrimary : AppColors.error)
                        .accessibilityHidden(true)
                    if isCorrect {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Correct! +\(lastPointsEarned) pts")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.brandPrimary)
                            if let breakdown = lastScoreBreakdown {
                                Text(breakdown)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    } else {
                        Text("Not quite — try the next one.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.error)
                    }
                }
                if !isCorrect {
                    Text("Correct: \(presentation.answers[presentation.correctIndex])")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                isCorrect
                    ? "Correct answer, \(lastPointsEarned) points"
                    : "Incorrect answer. Try the next question."
            )
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .animation(AppAnimation.quick, value: selectedAnswerIndex)

            reportIssueButton
        } else if timedOut, selectedAnswerIndex == nil {
            reportIssueButton
        } else if sessionComplete {
            Text("You've answered all questions.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: AppSpacing.stackItem) {
            if sessionComplete {
                Text("You've answered all questions.")
                    .appHelperText()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button(action: nextTapped) {
                if isLastQuestion {
                    Text("Finish")
                } else {
                    Text("Next Question")
                }
            }
            .buttonStyle(.appPrimary)
            .disabled(!isNextEnabled)
            .accessibilityLabel(isLastQuestion ? "Finish" : "Next Question")
            .accessibilityHint(
                isNextEnabled
                    ? (isLastQuestion ? "Completes the trivia round" : "Goes to the next question")
                    : (timedOut ? "Time expired — continue to the next question" : "Select an answer first")
            )
        }
        .appScreenHorizontalPadding()
        .padding(.top, AppSpacing.bottomBarTop)
        .padding(.bottom, AppSpacing.screenBottom)
        .brandScreenBackground()
    }

    // MARK: - Answer button

    private func answerButton(index: Int, text: String, correctIndex: Int) -> some View {
        let isLocked = selectedAnswerIndex != nil || timedOut
        let isSelected = selectedAnswerIndex == index
        let isCorrectAnswer = index == correctIndex
        let showResult = isLocked
        let isEmphasized = showResult && (isSelected || isCorrectAnswer)
        let letter = answerLetter(for: index)

        return Button {
            selectAnswer(index, correctIndex: correctIndex)
        } label: {
            HStack(spacing: 12) {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(answerTextColor(
                        showResult: showResult,
                        isSelected: isSelected,
                        isCorrectAnswer: isCorrectAnswer
                    ))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showResult && (isSelected || isCorrectAnswer) {
                    Image(systemName: isCorrectAnswer ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .font(.title3)
                        .foregroundStyle(isCorrectAnswer ? AppColors.brandPrimary : AppColors.error)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, AppSpacing.cardInnerHorizontal)
            .padding(.vertical, AppSpacing.cardInnerVertical)
            .frame(minHeight: max(AppMetrics.cardMinHeight, AppMetrics.minimumTouchTarget))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(answerBackground(
                showResult: showResult,
                isSelected: isSelected,
                isCorrectAnswer: isCorrectAnswer
            ))
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        answerBorderColor(
                            showResult: showResult,
                            isSelected: isSelected,
                            isCorrectAnswer: isCorrectAnswer
                        ),
                        lineWidth: showResult && (isSelected || isCorrectAnswer) ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked || timedOut)
        .appSelectionScale(isActive: isEmphasized, reduceMotion: reduceMotion)
        .animation(AppAnimation.quick, value: selectedAnswerIndex)
        .accessibilityLabel(answerAccessibilityLabel(letter: letter, text: text))
        .accessibilityHint(answerAccessibilityHint(
            isLocked: isLocked,
            isSelected: isSelected,
            isCorrectAnswer: isCorrectAnswer,
            showResult: showResult
        ))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func answerLetter(for index: Int) -> String {
        guard let scalar = UnicodeScalar(65 + index) else { return "\(index + 1)" }
        return String(Character(scalar))
    }

    private func answerAccessibilityLabel(letter: String, text: String) -> String {
        "Answer \(letter): \(text)"
    }

    private func answerAccessibilityHint(
        isLocked: Bool,
        isSelected: Bool,
        isCorrectAnswer: Bool,
        showResult: Bool
    ) -> String {
        if showResult {
            if isCorrectAnswer { return "Correct answer" }
            if isSelected { return "Your answer was incorrect" }
            return "Answer locked"
        }
        if isLocked { return "Answer locked" }
        return "Double tap to select this answer"
    }

    private func answerTextColor(showResult: Bool, isSelected: Bool, isCorrectAnswer: Bool) -> Color {
        if showResult {
            if isCorrectAnswer { return AppColors.brandPrimary }
            if isSelected { return AppColors.error }
        }
        return AppColors.textPrimary
    }

    private func answerBackground(showResult: Bool, isSelected: Bool, isCorrectAnswer: Bool) -> Color {
        if showResult {
            if isCorrectAnswer { return AppColors.brandPrimary.opacity(0.12) }
            if isSelected { return AppColors.error.opacity(0.08) }
        }
        return AppColors.cardBackground
    }

    private func answerBorderColor(showResult: Bool, isSelected: Bool, isCorrectAnswer: Bool) -> Color {
        if showResult {
            if isCorrectAnswer { return AppColors.brandPrimary }
            if isSelected { return AppColors.error }
        }
        return AppColors.cardBorder
    }

    // MARK: - Actions

    private func restoreOrStartRound() {
        if gameSession.correctAnswers == 0 {
            currentQuestionIndex = 0
            selectedAnswerIndex = nil
            sessionComplete = false
        } else {
            currentQuestionIndex = gameSession.currentQuestionIndex
        }
        loadPresentationForCurrentIndex()
    }

    private func loadPresentationForCurrentIndex() {
        guard currentQuestionIndex < questions.count else {
            currentPresentation = nil
            return
        }
        let question = questions[currentQuestionIndex]
        currentPresentation = QuestionBank.presentedQuestion(from: question)
        selectedAnswerIndex = nil
        timedOut = false
        lastPointsEarned = 0
        lastScoreBreakdown = nil
        timeRemaining = question.effectiveTimeLimitSeconds
    }

    private func runQuestionTimer() async {
        guard let presentation = currentPresentation else { return }
        timeRemaining = presentation.timeLimitSeconds
        while timeRemaining > 0 {
            if Task.isCancelled { return }
            if selectedAnswerIndex != nil || timedOut { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }
            if selectedAnswerIndex != nil || timedOut { return }
            timeRemaining -= 1
        }
        if selectedAnswerIndex == nil, !timedOut {
            handleTimedOut(presentation: presentation)
        }
    }

    private var reportIssueButton: some View {
        Button {
            showReportSheet = true
        } label: {
            Text("Report an issue with this question")
                .font(.footnote)
                .foregroundStyle(AppColors.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: AppMetrics.minimumTouchTarget)
        .accessibilityLabel("Report an issue with this question")
    }

    private func handleTimedOut(presentation: PresentedQuestion) {
        timedOut = true
        let breakdown = gameSession.recordAnswer(
            isCorrect: false,
            timeRemaining: 0,
            timeLimit: presentation.timeLimitSeconds,
            difficulty: presentation.difficulty
        )
        lastPointsEarned = breakdown.total
        lastScoreBreakdown = breakdown.total > 0 ? breakdown.breakdownLabel : nil
        recordQuestionOutcome(
            presentation: presentation,
            isCorrect: false,
            timedOut: true
        )
        Haptics.error()
    }

    private func selectAnswer(_ index: Int, correctIndex: Int) {
        guard selectedAnswerIndex == nil, !timedOut, let presentation = currentPresentation else { return }
        selectedAnswerIndex = index
        let isCorrect = index == correctIndex
        let breakdown = gameSession.recordAnswer(
            isCorrect: isCorrect,
            timeRemaining: timeRemaining,
            timeLimit: presentation.timeLimitSeconds,
            difficulty: presentation.difficulty
        )
        lastPointsEarned = breakdown.total
        lastScoreBreakdown = breakdown.total > 0 ? breakdown.breakdownLabel : nil
        recordQuestionOutcome(
            presentation: presentation,
            isCorrect: isCorrect,
            timedOut: false
        )
        if isCorrect {
            Haptics.success()
        } else {
            Haptics.error()
        }
    }

    private func recordQuestionOutcome(
        presentation: PresentedQuestion,
        isCorrect: Bool,
        timedOut: Bool
    ) {
        QuestionStatsStore.recordAnswer(
            catalogID: presentation.catalogID,
            isCorrect: isCorrect,
            timedOut: timedOut
        )
        analytics.track(.questionAnswered(
            catalogID: presentation.catalogID,
            isCorrect: isCorrect,
            category: presentation.category,
            difficulty: presentation.difficulty.rawValue,
            timedOut: timedOut,
            timeRemaining: timeRemaining
        ))
    }

    private func handleAppBackgrounded() {
        guard !sessionComplete, !gameSession.roundForfeited else { return }
        guard selectedAnswerIndex == nil, !timedOut, currentPresentation != nil else { return }

        gameSession.forfeitRound(
            reason: "You left the app during a timed question. This round was forfeited."
        )
        Haptics.error()
        onSessionComplete?()
    }

    private func nextTapped() {
        guard canProceedToNext, !sessionComplete, !gameSession.roundForfeited else { return }

        if isLastQuestion {
            gameSession.currentQuestionIndex = currentQuestionIndex
            onSessionComplete?()
            if onSessionComplete == nil {
                sessionComplete = true
            }
            return
        }

        currentQuestionIndex += 1
        gameSession.currentQuestionIndex = currentQuestionIndex
    }
}

#Preview {
    let session = GameSession()
    session.beginRound(categories: ["Auto City", "Local Legends"])
    return TriviaQuestionView()
        .environmentObject(session)
}
