//
//  QuestionReviewView.swift
//  JackpotTrivia
//

import SwiftUI

struct QuestionReviewView: View {
    @State private var refreshToken = UUID()

    private var catalogStats: (count: Int, categories: Int, version: Int, approved: Int) {
        QuestionCatalogLoader.catalogStats
    }

    private var flaggedIDs: [String] {
        let fromReports = QuestionReportStore.unreviewedCatalogIDs()
        let fromStats = QuestionStatsStore.flaggedQuestionIDs()
        return Array(Set(fromReports + fromStats)).sorted()
    }

    var body: some View {
        List {
            catalogSection
            flaggedSection
            retiredSection
        }
        .navigationTitle("Question Review")
        .navigationBarTitleDisplayMode(.inline)
        .id(refreshToken)
    }

    private var catalogSection: some View {
        Section {
            LabeledContent("Catalog version", value: "\(catalogStats.version)")
            LabeledContent("Total in JSON", value: "\(catalogStats.count)")
            LabeledContent("Approved in JSON", value: "\(catalogStats.approved)")
            LabeledContent("Playable in app", value: "\(QuestionBank.allQuestions.count)")
            LabeledContent("Categories", value: "\(catalogStats.categories)")

            let validationErrors = QuestionCatalogValidator.validateBundledCatalog()
            if validationErrors.isEmpty {
                Label("Catalog validation passed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.brandGreen)
            } else {
                Text("\(validationErrors.count) validation issue(s) — see unit tests for details.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Catalog health")
        } footer: {
            Text("Edit JackpotTrivia/Resources/QuestionCatalog.json. Locally retired IDs hide questions until JSON is updated.")
        }
    }

    private var flaggedSection: some View {
        Section {
            if flaggedIDs.isEmpty {
                Text("No flagged questions right now.")
                    .foregroundStyle(.secondary)
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
            let retired = QuestionRetirementStore.retiredCatalogIDs.sorted()
            if retired.isEmpty {
                Text("No locally retired questions.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(retired, id: \.self) { catalogID in
                    HStack {
                        Text(catalogID)
                            .font(.footnote)
                        Spacer()
                        Button("Restore") {
                            QuestionRetirementStore.unretire(catalogID: catalogID)
                            refreshToken = UUID()
                        }
                        .font(.footnote)
                    }
                }
            }
        } header: {
            Text("Locally retired")
        }
    }

  @ViewBuilder
    private func flaggedRow(catalogID: String) -> some View {
        let stats = QuestionStatsStore.stats(for: catalogID)
        let question = QuestionCatalogLoader.loadFromBundle().first { $0.catalogID == catalogID }

        VStack(alignment: .leading, spacing: 6) {
            Text(catalogID)
                .font(.caption)
                .foregroundStyle(.secondary)

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
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 8) {
                Button("Mark reviewed") {
                    QuestionReportStore.markReviewed(catalogID: catalogID)
                    refreshToken = UUID()
                }
                .font(.caption)

                Button("Retire") {
                    QuestionRetirementStore.retire(catalogID: catalogID)
                    refreshToken = UUID()
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        QuestionReviewView()
    }
}
