//
//  ChallengeService.swift
//  JackpotTrivia
//
//  Friend challenges via deep link until server-side matchmaking exists.
//

import Foundation

struct FriendChallenge: Codable, Equatable {
    let challengerName: String
    let points: Int
    let accuracyPercent: Int
    let dayKey: String
    let createdAt: Date

    var message: String {
        "\(challengerName) scored \(points) pts (\(accuracyPercent)% accuracy) on \(dayKey). Can you beat it?"
    }
}

enum ChallengeService {
    static let urlScheme = InviteLinkService.inviteURLScheme

    private static let pendingChallengeKey = "jackpotTrivia.challenge.pending"

    // MARK: - Create

    static func makeChallenge(
        challengerName: String,
        points: Int,
        correctAnswers: Int,
        totalQuestions: Int,
        dayKey: String = DailyGameService.dayKey()
    ) -> FriendChallenge {
        let accuracy = totalQuestions > 0
            ? Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
            : 0
        return FriendChallenge(
            challengerName: challengerName,
            points: points,
            accuracyPercent: accuracy,
            dayKey: dayKey,
            createdAt: .now
        )
    }

    static func challengeURL(for challenge: FriendChallenge) -> URL? {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = "challenge"
        components.queryItems = [
            URLQueryItem(name: "from", value: challenge.challengerName),
            URLQueryItem(name: "points", value: "\(challenge.points)"),
            URLQueryItem(name: "accuracy", value: "\(challenge.accuracyPercent)"),
            URLQueryItem(name: "day", value: challenge.dayKey),
        ]
        return components.url
    }

    static func shareText(for challenge: FriendChallenge) -> String {
        let link = challengeURL(for: challenge)?.absoluteString ?? ""
        return "\(challenge.message) Play Jackpot Trivia: \(link)"
    }

    // MARK: - Parse

    static func parseChallenge(from raw: String) -> FriendChallenge? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              url.scheme?.lowercased() == urlScheme,
              url.host?.lowercased() == "challenge",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return nil
        }

        func value(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        guard let from = value("from"),
              let pointsStr = value("points"), let points = Int(pointsStr),
              let accuracyStr = value("accuracy"), let accuracy = Int(accuracyStr),
              let day = value("day") else {
            return nil
        }

        return FriendChallenge(
            challengerName: from,
            points: points,
            accuracyPercent: accuracy,
            dayKey: day,
            createdAt: .now
        )
    }

    // MARK: - Pending challenge (beat my score)

    static var pendingChallenge: FriendChallenge? {
        get {
            guard let data = UserDefaults.standard.data(forKey: pendingChallengeKey),
                  let decoded = try? JSONDecoder().decode(FriendChallenge.self, from: data) else {
                return nil
            }
            return decoded
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: pendingChallengeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: pendingChallengeKey)
            }
        }
    }

    static func clearPendingChallenge() {
        pendingChallenge = nil
    }

    static func handleIncomingURL(_ url: URL) -> FriendChallenge? {
        guard let challenge = parseChallenge(from: url.absoluteString) else { return nil }
        pendingChallenge = challenge
        return challenge
    }
}
