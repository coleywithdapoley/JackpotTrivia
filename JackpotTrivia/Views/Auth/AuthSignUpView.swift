//
//  AuthSignUpView.swift
//  JackpotTrivia
//

import SwiftUI

struct AuthSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthManager

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.fieldToAction) {
                Text("Create account")
                    .appScreenTitle()
                    .padding(.top, AppSpacing.section)

                authField(label: "Display name (optional)", text: $displayName, contentType: .name)
                authField(label: "Email", text: $email, contentType: .username, keyboard: .emailAddress)
                authSecureField(label: "Password", text: $password)
                authSecureField(label: "Confirm password", text: $confirmPassword)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(action: signUpTapped) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign Up")
                    }
                }
                .buttonStyle(.appPrimary)
                .disabled(isLoading)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func authField(
        label: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
            Text(label).appFieldLabel()
            TextField(label, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
        }
    }

    private func authSecureField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
            Text(label).appFieldLabel()
            SecureField(label, text: text)
                .textContentType(.newPassword)
                .padding()
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
        }
    }

    private func signUpTapped() {
        errorMessage = nil
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        isLoading = true
        Task {
            do {
                try await auth.signUp(email: email, password: password, displayName: displayName)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        AuthSignUpView()
            .environmentObject(AuthManager.shared)
    }
}
