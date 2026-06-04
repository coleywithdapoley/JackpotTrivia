//
//  ForgotPasswordView.swift
//  JackpotTrivia
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthManager

    @State private var recoveryMode: RecoveryMode = .email
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    private enum RecoveryMode: String, CaseIterable, Identifiable {
        case email
        case sms

        var id: String { rawValue }

        var title: String {
            switch self {
            case .email: return "Email"
            case .sms: return "SMS"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.fieldToAction) {
                Text("Reset password")
                    .appScreenTitle()
                    .padding(.top, AppSpacing.section)

                Text("We'll send reset instructions to your email or phone.")
                    .appBodyText()
                    .fixedSize(horizontal: false, vertical: true)

                Picker("Recovery method", selection: $recoveryMode) {
                    ForEach(RecoveryMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch recoveryMode {
                case .email:
                    VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
                        Text("Email").appFieldLabel()
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                    }
                case .sms:
                    VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
                        Text("Phone number").appFieldLabel()
                        TextField("(555) 123-4567", text: $phoneNumber)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                    }
                }

                if let successMessage {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(AppColors.brandGreen)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(action: sendResetTapped) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send reset link")
                    }
                }
                .buttonStyle(.appPrimary)
                .disabled(isLoading)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendResetTapped() {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        Task {
            do {
                switch recoveryMode {
                case .email:
                    try await auth.sendPasswordResetEmail(to: email)
                    successMessage = "If an account exists, reset instructions were sent to your email."
                case .sms:
                    try await auth.sendPasswordResetSMS(to: phoneNumber)
                    successMessage = "If an account exists, a reset code was sent via SMS."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(AuthManager.shared)
    }
}
