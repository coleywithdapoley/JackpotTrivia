//
//  SocialShareService.swift
//  JackpotTrivia
//

import Foundation

enum SocialShareService {
    static func resultsShareText(
        session: GameSession,
        user: AuthUser?,
        rank: LeaderboardStanding?
    ) -> String {
        let name = user?.displayName ?? user?.email ?? "I"
        let accuracy = session.totalQuestions > 0
            ? Int((Double(session.correctAnswers) / Double(session.totalQuestions) * 100).rounded())
            : 0
        var lines = [
            "\(name) scored \(session.roundPoints) pts on \(AppConfig.appDisplayName)!",
            "\(session.correctAnswers)/\(session.totalQuestions) correct (\(accuracy)% accuracy).",
        ]
        if let rank {
            lines.append("Ranked #\(rank.rank) \(rank.entry.points) pts today.")
        }
        lines.append("Download and play the daily jackpot!")
        return lines.joined(separator: "\n")
    }
}
