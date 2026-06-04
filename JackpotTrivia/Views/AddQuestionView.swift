//
//  AddQuestionView.swift
//  JackpotTrivia
//
//  Lets founders add MCQ / true-false questions on device (merged into play pool).
//

import SwiftUI

struct AddQuestionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var catalogID = ""
    @State private var category = AppConfig.defaultCategories.first ?? "General Knowledge"
    @State private var questionText = ""
    @State private var answers: [String] = ["", "", "", ""]
    @State private var correctIndex = 0
    @State private var questionType: QuestionType = .multipleChoice
    @State private var difficulty: QuestionDifficulty = .medium
    @State private var allowsMature = false
    @State private var errorMessage: String?
    @State private var savedID: String?

    var body: some View {
        Form {
            Section("Question") {
                TextField("Unique ID (e.g. hist-jfk-1960)", text: $catalogID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Picker("Category", selection: $category) {
                    ForEach(AppConfig.defaultCategories, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }

                TextField("Question text", text: $questionText, axis: .vertical)
                    .lineLimit(3...6)

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
            }

            Section("Answers") {
                if questionType == .trueFalse {
                    Picker("Correct answer", selection: $correctIndex) {
                        Text("True").tag(0)
                        Text("False").tag(1)
                    }
                } else {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("Answer \(index + 1)", text: binding(for: index))
                    }
                    Picker("Correct answer", selection: $correctIndex) {
                        ForEach(0..<4, id: \.self) { index in
                            Text("Option \(index + 1)").tag(index)
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            if let savedID {
                Section {
                    Label("Saved as \(savedID)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.brandGreen)
                }
            }

            Section {
                Button("Save question") {
                    saveQuestion()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Add question")
        .navigationBarTitleDisplayMode(.inline)
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
        savedID = nil

        let slug = catalogID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")

        guard slug.count >= 3 else {
            errorMessage = "ID must be at least 3 characters."
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

        let stem = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard stem.count >= 8 else {
            errorMessage = "Question text is too short."
            return
        }

        guard correctIndex >= 0, correctIndex < trimmedAnswers.count else {
            errorMessage = "Pick a valid correct answer."
            return
        }

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
            source: "admin-device",
            verifiedAt: ISO8601DateFormatter().string(from: .now)
        )

        let file = QuestionCatalogFile(version: 1, questions: [item])
        let errors = QuestionCatalogValidator.validate(file: file)
        if let first = errors.first {
            errorMessage = String(describing: first)
            return
        }

        guard QuestionCatalogStore.append(item) != nil else {
            errorMessage = "Could not save question."
            return
        }

        savedID = slug
        Haptics.success()
    }
}

#Preview {
    NavigationStack {
        AddQuestionView()
    }
}
