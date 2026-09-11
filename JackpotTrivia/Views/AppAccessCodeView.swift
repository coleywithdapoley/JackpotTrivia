//
//  AppAccessCodeView.swift
//  JackpotTrivia
//

import SwiftUI

struct AppAccessCodeView: View {
    @Environment(\.analytics) private var analytics

    var onAccessGranted: () -> Void = {}

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                Text(AppConfig.Copy.accessCodeTitle)
                    .appScreenTitle()

                Text(AppConfig.Copy.authSubtitle)
                    .appBodyText()
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
                    Text("Access code")
                        .appFieldLabel()
                    TextField("Enter access code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(AppColors.error)
                }

                Button(action: unlockTapped) {
                    if isLoading {
                        ProgressView().tint(AppColors.textOnPrimary)
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(.appPrimary)
                .disabled(isLoading || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text(AppConfig.Copy.accessCodeFooter)
                    .appCaptionText()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appScreenHorizontalPadding()
            .padding(.vertical, AppSpacing.section)
        }
        .brandScreenBackground()
        .navigationTitle("Join")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unlockTapped() {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try LocalAppAccessService.shared.redeemAccessCode(code)
            analytics.track(.appAccessRedeemed(success: true))
            Haptics.success()
            onAccessGranted()
        } catch {
            analytics.track(.appAccessRedeemed(success: false))
            errorMessage = AccessCodeRedemptionError.invalidOrExpired.userMessage
            Haptics.error()
        }
    }
}

#Preview {
    NavigationStack {
        AppAccessCodeView()
    }
}
