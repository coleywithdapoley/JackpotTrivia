//
//  AddQuestionView.swift
//  JackpotTrivia
//
//  Admin types a question and answers as regular text. No JSON editing.
//  A catalog ID is generated behind the scenes for the live pool.
//

import SwiftUI

struct AddQuestionView: View {
    @EnvironmentObject private var auth: AuthManager

    @State private var category = AppConfig.defaultCategories.first ?? "Auto City"
    @State private var questionText = ""
    @State private var answers: [String] = ["", "", "", ""]
    @State private var correctIndex = 0
    @State private var questionType: QuestionType = .multipleChoice
    @State private var difficulty: QuestionDifficulty = .medium
    @State private var allowsMature = false
    @State private var errorMessage: String?
    @State private var didSave = false
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Picker("Category", selection: $category) {
                    ForEach(AppConfig.defaultCategories, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }

                TextField("Type the question", text: $questionText, axis: .vertical)
                    .lineLimit(3...8)
                    .textInputAutocapitalization(.sentences)

                Picker("Type", selection: $questionType) {
                    Text("Multiple choice").tag(QuestionType.multipleChoice)
                    Text("True / False").tag(QuestionType.trueFalse)
                }
                .onChange(of: questionType) { _, type in
                    if type == .trueFalse {
                        answers = QuestionType.trueFalseAnswers
                        correctIndex = 0
                    } else if answers.count < 4 {
                        answers = ["", "", "", ""]
                    }
                }

                Picker("Difficulty", selection: $difficulty) {
                    ForEach(QuestionDifficulty.allCases, id: \.self) { tier in
                        Text(tier.rawValue.capitalized).tag(tier)
                    }
                }

                Toggle("18+ / mature topic", isOn: $allowsMature)
            } header: {
                Text("Question")
            } footer: {
                Text("Type it the way players should read it. You don’t edit JSON.")
            }

            Section("Answers") {
                if questionType == .trueFalse {
                    Picker("Correct answer", selection: $correctIndex) {
                        Text("True").tag(0)
                        Text("False").tag(1)
                    }
                } else {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("Answer \(index + 1)", text: binding(for: index), axis: .vertical)
                            .lineLimit(1...3)
                            .textInputAutocapitalization(.sentences)
                    }
                    Picker("Correct answer", selection: $correctIndex) {
                        ForEach(0..<4, id: \.self) { index in
                            let label = answers.indices.contains(index) && !answers[index].isEmpty
                                ? answers[index]
                                : "Answer \(index + 1)"
                            Text(label).tag(index)
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(AppColors.error)
                        .font(.footnote)
                }
            }

            if didSave {
                Section {
                    Label("Saved. Every signed-in player can get this question.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.brandPrimary)
                }
            }

            Section {
                Button(isSaving ? "Saving…" : "Save question") {
                    saveQuestion()
                }
                .disabled(isSaving)
                .frame(maxWidth: .infinity)
            } footer: {
                Text(SupabaseConfig.isConfigured
                     ? "This goes live for every signed-in player. They see it after they reopen the app or return to Home."
                     : "Supabase is not configured — this save stays on this device only.")
            }
        }
        .navigationTitle("Add question")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isSaving {
                ProgressView()
            }
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { answers.indices.contains(index) ? answers[index] : "" },
            set: { newValue in
                while answers.count <= index { answers.append("") }
                answers[index] = newValue
            }
        )
    }

    private func saveQuestion() {
        errorMessage = nil
        didSave = false

        let stem = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard stem.count >= 8 else {
            errorMessage = "Type a full question."
            return
        }

        let trimmedAnswers: [String]
        if questionType == .trueFalse {
            trimmedAnswers = QuestionType.trueFalseAnswers
        } else {
            trimmedAnswers = answers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard trimmedAnswers.allSatisfy({ !$0.isEmpty }) else {
                errorMessage = "Fill in all four answers."
                return
            }
        }

        guard correctIndex >= 0, correctIndex < trimmedAnswers.count else {
            errorMessage = "Pick which answer is correct."
            return
        }

        let slug = AdminQuestionSlug.make(from: stem)
        let item = QuestionCatalogItem(
            id: slug,
            category: category,
            question: stem,
            answers: trimmedAnswers,
            correctIndex: correctIndex,
            questionType: questionType.rawValue,
            difficulty: difficulty.rawValue,
            timeLimitSeconds: nil,
            allowsMatureTopics: allowsMature,
            isEducational: !allowsMature,
            isFamilySafe: !allowsMature,
            status: QuestionStatus.approved.rawValue,
            source: "admin-app",
            verifiedAt: ISO8601DateFormatter().string(from: .now)
        )

        let file = QuestionCatalogFile(version: 1, questions: [item])
        if let first = QuestionCatalogValidator.validate(file: file).first {
            errorMessage = humanReadable(first)
            return
        }

        if SupabaseConfig.isConfigured {
            guard auth.isAdmin, let token = SupabaseSessionStore.current?.accessToken else {
                errorMessage = "Sign in as admin, then save again."
                return
            }
            isSaving = true
            Task {
                do {
                    try await QuestionRepository.shared.publishQuestion(item, accessToken: token)
                    finishSuccessfulSave()
                } catch {
                    errorMessage = friendlyPublishError(error)
                }
                isSaving = false
            }
            return
        }

        guard QuestionCatalogStore.append(item) != nil else {
            errorMessage = "Could not save question."
            return
        }

        finishSuccessfulSave()
    }

    private func finishSuccessfulSave() {
        didSave = true
        questionText = ""
        answers = questionType == .trueFalse ? QuestionType.trueFalseAnswers : ["", "", "", ""]
        correctIndex = 0
        Haptics.success()
    }

    private func humanReadable(_ error: QuestionCatalogValidationError) -> String {
        switch error {
        case .duplicateQuestionText:
            return "That question is already in the catalog."
        case .unknownCategory(_, let category):
            return "Pick a category from the list (\(category) isn’t one)."
        case .invalidCorrectIndex:
            return "Pick which answer is correct."
        case .invalidTrueFalseAnswers:
            return "True / False answers have to be True and False."
        case .duplicateID, .missingID:
            return "Could not save this question. Try again."
        }
    }

    private func friendlyPublishError(_ error: Error) -> String {
        let text = error.localizedDescription
        if text.lowercased().contains("23505") || text.lowercased().contains("duplicate") {
            return "That question is already live."
        }
        if text.lowercased().contains("42501") || text.lowercased().contains("row-level") {
            return "This account is not allowed to add live questions."
        }
        return text
    }
}

enum AdminQuestionSlug {
    static func make(from question: String) -> String {
        let words = question
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
            .prefix(6)
        let base = words.joined(separator: "-")
        let stem = base.isEmpty ? "question" : String(base.prefix(48))
        return "admin-\(stem)-\(UUID().uuidString.prefix(8).lowercased())"
    }
}

#Preview {
    NavigationStack {
        AddQuestionView()
            .environmentObject(AuthManager.shared)
    }
}
