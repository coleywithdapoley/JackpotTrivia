//
//  QuickHitResultsView.swift
//  JackpotTrivia
//

import SwiftUI

struct QuickHitResultsView: View {
    @EnvironmentObject private var gameSession: GameSession

    var onCreateAccount: () -> Void = {}
    var onSignIn: () -> Void = {}

    private var correctAnswers: Int { gameSession.correctAnswers }
    private var totalQuestions: Int { gameSession.totalQuestions }

    private var accuracyPercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
    }

    private var resultsHeadline: String {
        guard totalQuestions > 0 else { return AppConfig.Copy.quickHitResultsTitle }
        let strongThreshold = Int(
            (Double(AppConfig.Copy.highScoreAccuracyThreshold) / 100.0 * Double(totalQuestions)).rounded(.up)
        )
        return correctAnswers >= strongThreshold
            ? AppConfig.Copy.quickHitResultsTitleStrong
            : AppConfig.Copy.quickHitResultsTitle
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(resultsHeadline)
                    .appScreenTitle()
                    .padding(.top, AppSpacing.sectionLarge)

                scoreCard
                    .padding(.top, AppSpacing.section)

                Text(AppConfig.Copy.quickHitResultsCTA)
                    .appBodyText()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                    .padding(.top, AppSpacing.section)

                Button(action: onCreateAccount) {
                    Text(AppConfig.Copy.quickHitCreateAccountCTA)
                }
                .buttonStyle(.appPrimary)
                .padding(.top, AppSpacing.section)

                Button(action: onSignIn) {
                    Text(AppConfig.Copy.quickHitSignInCTA)
                }
                .buttonStyle(.appSecondary)
                .padding(.top, AppSpacing.stackItem)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .brandScreenBackground()
        .onAppear {
            gameSession.finalizeRound(for: nil)
            Haptics.success()
        }
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("\(correctAnswers) of \(totalQuestions) correct")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.brandPrimary)

            Text("\(accuracyPercentage)% accuracy")
                .appHelperText()

            if gameSession.roundPoints > 0 {
                Text("+\(gameSession.roundPoints) preview XP — doesn't count until you join")
                    .appCaptionText()
            }
        }
        .padding(AppSpacing.cardInnerHorizontal)
        .padding(.vertical, AppSpacing.cardInnerVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.brandSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(AppColors.brandPrimary.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }
}

#Preview {
    QuickHitResultsView()
        .environmentObject(GameSession())
}
