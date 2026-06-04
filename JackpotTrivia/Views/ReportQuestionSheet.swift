//
//  ReportQuestionSheet.swift
//  JackpotTrivia
//

import SwiftUI

struct ReportQuestionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.analytics) private var analytics
    @EnvironmentObject private var auth: AuthManager

    let catalogID: String
    var onSubmitted: () -> Void = {}

    @State private var selectedReason: QuestionReportReason = .wrongAnswer

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Text("What is wrong with this question?")
                    .appScreenSubtitle()

                Picker("Reason", selection: $selectedReason) {
                    ForEach(QuestionReportReason.allCases) { reason in
                        Text(reason.displayName).tag(reason)
                    }
                }
                .pickerStyle(.inline)

                Text("Question ID: \(catalogID)")
                    .appCaptionText()

                Button(action: submitTapped) {
                    Text("Submit report")
                }
                .buttonStyle(.appPrimary)

                Spacer()
            }
            .appScreenHorizontalPadding()
            .padding(.top, AppSpacing.section)
            .navigationTitle("Report issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitTapped() {
        QuestionReportStore.submit(
            catalogID: catalogID,
            reason: selectedReason,
            userID: auth.currentUser?.id
        )
        analytics.track(.questionReported(
            catalogID: catalogID,
            reason: selectedReason.rawValue
        ))
        onSubmitted()
        dismiss()
    }
}

#Preview {
    ReportQuestionSheet(catalogID: "gk-capital-france")
        .environmentObject(AuthManager.shared)
}
