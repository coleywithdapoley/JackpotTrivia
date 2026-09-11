//
//  QuestionReviewView.swift
//  JackpotTrivia
//

import SwiftUI

struct QuestionReviewView: View {
    @State private var refreshToken = UUID()
    @State private var actionError: String?
    @State private var isWorking = false

    private var catalogStats: (count: Int, categories: Int, version: Int, approved: Int) {
        QuestionCatalogLoader.catalogStats
    }

    private var flaggedIDs: [String] {
        let fromReports = QuestionReportStore.unreviewedCatalogIDs()
        let fromStats = QuestionStatsStore.flaggedQuestionIDs()
        return Array(Set(fromReports + fromStats)).sorted()
    }

    private var bundledIDs: Set<String> {
        Set(QuestionCatalogLoader.loadFromBundle().map(\.catalogID))
    }

    private var remoteOnlyIDs: [String] {
        QuestionRepository.shared.remoteQuestions
            .map(\.catalogID)
            .filter { !bundledIDs.contains($0) }
            .sorted()
    }

    private var retiredIDs: [String] {
        QuestionRetirementStore.retiredCatalogIDs
            .union(QuestionRepository.shared.retiredCatalogSlugs)
            .sorted()
    }

    var body: some View {
        List {
            catalogSection
            liveExtrasSection
            flaggedSection
            retiredSection
            if let actionError {
                Section {
                    Text(actionError)
                        .font(.footnote)
                        .foregroundStyle(AppColors.error)
                }
            }
        }
        .navigationTitle("Question Review")
        .navigationBarTitleDisplayMode(.inline)
        .id(refreshToken)
        .overlay {
            if isWorking { ProgressView() }
        }
    }

    private var catalogSection: some View {
        Section {
            LabeledContent("Catalog version", value: "\(catalogStats.version)")
            LabeledContent("Total in JSON", value: "\(catalogStats.count)")
            LabeledContent("Approved in JSON", value: "\(catalogStats.approved)")
            LabeledContent("Playable in app", value: "\(QuestionBank.allQuestions.count)")
            LabeledContent("Live extras", value: "\(remoteOnlyIDs.count)")
            LabeledContent("Categories", value: "\(catalogStats.categories)")

            let validationErrors = QuestionCatalogValidator.validateBundledCatalog()
            if validationErrors.isEmpty {
                Label("Catalog validation passed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.brandPrimary)
            } else {
                Text("\(validationErrors.count) validation issue(s) — see unit tests for details.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.error)
            }
        } header: {
            Text("Catalog health")
        } footer: {
            Text("Edit JackpotTrivia/Resources/QuestionCatalog.json for a new app build. Retire / Restore here updates every signed-in player.")
        }
    }

    private var liveExtrasSection: some View {
        Section {
            if remoteOnlyIDs.isEmpty {
                Text("No extra live questions yet. Add one from Access Settings.")
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(remoteOnlyIDs, id: \.self) { catalogID in
                    VStack(alignment: .leading, spacing: 6) {
                        if let text = QuestionRepository.shared.remoteQuestions.first(where: { $0.catalogID == catalogID })?.question {
                            Text(text)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack {
                            Spacer()
                            Button("Retire", role: .destructive) {
                                runCatalogAction { try await QuestionRepository.shared.retireQuestion(catalogID: catalogID, accessToken: $0) }
                            }
                            .font(.caption)
                            .disabled(isWorking)
                        }
                    }
                }
            }
        } header: {
            Text("Added for all players")
        } footer: {
            Text("Questions published from this app. Retire removes them from every signed-in player.")
        }
    }

    private var flaggedSection: some View {
        Section {
            if flaggedIDs.isEmpty {
                Text("No flagged questions right now.")
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(flaggedIDs, id: \.self) { catalogID in
                    flaggedRow(catalogID: catalogID)
                }
            }
        } header: {
            Text("Flagged for review")
        } footer: {
            Text("Includes unreviewed player reports and high miss-rate questions (5+ plays, 65%+ miss).")
        }
    }

    private var retiredSection: some View {
        Section {
            let retired = retiredIDs
            if retired.isEmpty {
                Text("No retired questions.")
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(retired, id: \.self) { catalogID in
                    HStack {
                        Text(catalogID)
                            .font(.footnote)
                        Spacer()
                        Button("Restore") {
                            runCatalogAction { try await QuestionRepository.shared.restoreQuestion(catalogID: catalogID, accessToken: $0) }
                        }
                        .font(.footnote)
                        .disabled(isWorking)
                    }
                }
            }
        } header: {
            Text("Retired for all players")
        }
    }

  @ViewBuilder
    private func flaggedRow(catalogID: String) -> some View {
        let stats = QuestionStatsStore.stats(for: catalogID)
        let question = QuestionCatalogLoader.loadFromBundle().first { $0.catalogID == catalogID }

        VStack(alignment: .leading, spacing: 6) {
            Text(catalogID)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)

            if let question {
                Text(question.question)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                if stats.timesShown > 0 {
                    Text("\(Int(stats.missRate * 100))% miss (\(stats.timesShown) plays)")
                        .font(.caption2)
                }
                if stats.reportCount > 0 {
                    Text("\(stats.reportCount) report(s)")
                        .font(.caption2)
                        .foregroundStyle(AppColors.error)
                }
            }

            HStack(spacing: 8) {
                Button("Mark reviewed") {
                    QuestionReportStore.markReviewed(catalogID: catalogID)
                    refreshToken = UUID()
                }
                .font(.caption)

                Button("Retire") {
                    runCatalogAction { try await QuestionRepository.shared.retireQuestion(catalogID: catalogID, accessToken: $0) }
                }
                .font(.caption)
                .foregroundStyle(AppColors.error)
                .disabled(isWorking)
            }
        }
        .padding(.vertical, 4)
    }

    private func runCatalogAction(_ work: @escaping (String) async throws -> Void) {
        actionError = nil
        guard SupabaseConfig.isConfigured else {
            actionError = "Supabase is not configured on this build."
            return
        }
        guard let token = SupabaseSessionStore.current?.accessToken else {
            actionError = "Sign in as admin, then try again."
            return
        }
        isWorking = true
        Task {
            do {
                try await work(token)
                refreshToken = UUID()
            } catch {
                actionError = error.localizedDescription
            }
            isWorking = false
        }
    }
}

#Preview {
    NavigationStack {
        QuestionReviewView()
    }
}
