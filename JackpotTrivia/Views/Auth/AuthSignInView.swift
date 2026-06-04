//
//  AuthSignInView.swift
//  JackpotTrivia
//

import SwiftUI

struct AuthSignInView: View {
    @EnvironmentObject private var auth: AuthManager

    var onSignUp: () -> Void = {}
    var onForgotPassword: () -> Void = {}

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, AppSpacing.heroTop)

                form
                    .padding(.top, AppSpacing.section + AppSpacing.labelToField)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, AppSpacing.stackItem)
                        .accessibilityLabel("Error: \(errorMessage)")
                }

                Button(action: signInTapped) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(.appPrimary)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.top, AppSpacing.fieldToAction)

                Button("Create account", action: onSignUp)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.brandGreen)
                    .frame(maxWidth: .infinity, minHeight: AppMetrics.minimumTouchTarget)

                Button("Forgot password?", action: onForgotPassword)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: AppMetrics.minimumTouchTarget)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.brandGreen)
                .accessibilityHidden(true)

            Text(AppConfig.appDisplayName)
                .appScreenTitle()

            Text(AppConfig.Copy.tagline)
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)

            Text(AppConfig.Copy.authSubtitle)
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldToAction) {
            VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
                Text("Email")
                    .appFieldLabel()
                TextField("you@example.com", text: $email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            }

            VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
                Text("Password")
                    .appFieldLabel()
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            }
        }
    }

    private func signInTapped() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await auth.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthSignInView()
        .environmentObject(AuthManager.shared)
}
