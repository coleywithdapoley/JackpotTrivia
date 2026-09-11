//
//  CategorySelectionView.swift
//  JackpotTrivia
//

import SwiftUI

// MARK: - Model

struct TriviaCategory: Identifiable, Equatable {
    let id: UUID
    let name: String
    let imageAsset: String?
    let emoji: String?
    let description: String?

    static let sampleCategories: [TriviaCategory] = {
        AppConfig.defaultCategories.map { name in
            TriviaCategory(
                id: UUID(),
                name: name,
                imageAsset: AppConfig.imageAsset(forCategory: name),
                emoji: AppConfig.emoji(forCategory: name),
                description: AppConfig.description(forCategory: name)
            )
        }
    }()
}

// MARK: - View

struct CategorySelectionView: View {
    @EnvironmentObject private var gameSession: GameSession
    @Environment(\.analytics) private var analytics
    @Environment(\.featureGates) private var featureGates

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onStartTrivia: () -> Void = {}

    private let categories = TriviaCategory.sampleCategories

    @State private var playMode: GamePlayMode = .chooseCategories
    @State private var selectedMood: TriviaMood = .familyGameNight
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var narrowToSingleCategory = false
    @State private var showCategoryUpgradeHint = false
    @State private var showInviteFriends = false

    private var selectedCategories: [TriviaCategory] {
        categories.filter { selectedCategoryIDs.contains($0.id) }
    }

    private var effectiveCategoryNames: [String] {
        if playMode == .partyMode { return [] }
        if selectedMood != .custom {
            return AppConfig.categories(for: selectedMood)
        }
        return selectedCategories.map(\.name)
    }

    private var isStartEnabled: Bool {
        switch playMode {
        case .partyMode:
            return true
        case .chooseCategories:
            if selectedMood != .custom { return true }
            return !selectedCategoryIDs.isEmpty
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, AppSpacing.section)

                playModeSection
                    .padding(.top, AppSpacing.sectionLarge)

                moodSection
                    .padding(.top, AppSpacing.sectionLarge)

                if playMode == .chooseCategories, selectedMood == .custom {
                    categoryList
                        .padding(.top, AppSpacing.sectionLarge)

                    narrowCategoryToggle
                        .padding(.top, AppSpacing.stackItem)
                }

                tierFootnotes
                    .padding(.top, AppSpacing.stackItem)

                comfortLink
                    .padding(.top, AppSpacing.stackItem)

                inviteFriendsButton
                    .padding(.top, AppSpacing.stackItem)
            }
            .appScreenHorizontalPadding()
            .padding(.bottom, AppSpacing.section)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .brandScreenBackground()
        .sheet(isPresented: $showInviteFriends) {
            InviteFriendsSheet()
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.bottomBarTop)
                .padding(.bottom, AppSpacing.screenBottom)
                .background {
                    AppColors.brandBackground
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(AppColors.subtleBorder)
                                .frame(height: 1)
                        }
                        .ignoresSafeArea()
                }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.labelToField) {
            Text("Start a Game")
                .appScreenTitle()
                .accessibilityAddTraits(.isHeader)

            Text("Pick how you want to play — categories, party mode, or a mood preset.")
                .appBodyText()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var playModeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Session type")
                .appFieldLabel()

            ForEach(GamePlayMode.allCases) { mode in
                playModeCard(mode)
            }
        }
    }

    private func playModeCard(_ mode: GamePlayMode) -> some View {
        let isSelected = playMode == mode
        return Button {
            playMode = mode
            showCategoryUpgradeHint = false
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: mode == .partyMode ? "sparkles" : "square.grid.2x2")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.brandPrimaryOnDark : AppColors.textSecondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(mode.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.brandPrimaryOnDark : AppColors.textTertiary)
            }
            .padding(AppSpacing.cardInnerHorizontal)
            .padding(.vertical, AppSpacing.cardInnerVertical)
            .frame(minHeight: max(AppMetrics.minimumTouchTarget, 56))
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSelectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stackItem) {
            Text("Mood")
                .appFieldLabel()

            Text("Mood-based trivia pulls categories automatically. Choose Custom to pick categories yourself.")
                .appHelperText()
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.stackItem) {
                    ForEach(TriviaMood.allCases) { mood in
                        moodChip(mood)
                    }
                }
            }
        }
    }

    private func moodChip(_ mood: TriviaMood) -> some View {
        let isSelected = selectedMood == mood
        return Button {
            selectedMood = mood
            if mood != .custom {
                selectedCategoryIDs.removeAll()
            }
        } label: {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isSelected ? AppColors.textOnPrimary : AppColors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minWidth: 92, minHeight: AppMetrics.minimumTouchTarget)
            .background(isSelected ? AppColors.brandPrimary : AppColors.brandSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.brandPrimaryOnDark : AppColors.subtleBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood \(mood.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var categoryList: some View {
        LazyVStack(spacing: AppSpacing.stackItem + 4) {
            ForEach(categories) { category in
                categoryRow(category)
            }
        }
    }

    private var narrowCategoryToggle: some View {
        Toggle("Advanced: focus on one category only", isOn: $narrowToSingleCategory)
            .font(.subheadline)
            .foregroundStyle(AppColors.textPrimary)
            .tint(AppColors.brandPrimary)
            .disabled(selectedCategoryIDs.count != 1)
    }

    @ViewBuilder
    private var tierFootnotes: some View {
        if playMode == .partyMode {
            Text("Party mode: random questions from every category.")
                .appCaptionText()
        } else if selectedMood != .custom {
            Text("Using mood \"\(selectedMood.displayName)\" — \(effectiveCategoryNames.joined(separator: ", "))")
                .appCaptionText()
                .fixedSize(horizontal: false, vertical: true)
        }

        if featureGates.isFreeTier, playMode == .chooseCategories, selectedMood == .custom {
            Text("This beta allows up to \(featureGates.maxCategoriesSelectable) categories per round.")
                .appCaptionText()
        }

        if showCategoryUpgradeHint {
            Text("This beta allows up to \(featureGates.maxCategoriesSelectable) categories per round.")
                .appCaptionText()
        }
    }

    private var comfortLink: some View {
        NavigationLink {
            ComfortPreferencesView()
        } label: {
            Label("Comfort & content filters", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .foregroundStyle(AppColors.brandPrimaryOnDark)
        }
    }

    @ViewBuilder
    private var inviteFriendsButton: some View {
        if InviteLinkService.currentMemberID != nil {
            Button {
                showInviteFriends = true
            } label: {
                Label(
                    "Invite friends (\(InviteLinkService.remainingReferralsForCurrentMember) left)",
                    systemImage: "person.badge.plus"
                )
                .font(.subheadline)
                .foregroundStyle(AppColors.brandPrimary)
            }
        }
    }

    private func categoryRow(_ category: TriviaCategory) -> some View {
        let isSelected = selectedCategoryIDs.contains(category.id)

        return Button {
            toggleSelection(for: category.id)
        } label: {
            HStack(spacing: 14) {
                CategoryArtwork(category: category.name, size: 52, cornerRadius: 10, isDimmed: !isSelected)

                VStack(alignment: .leading, spacing: 6) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                    if let description = category.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.brandPrimaryOnDark : AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.cardInnerHorizontal)
            .padding(.vertical, AppSpacing.cardInnerVertical + 2)
            .frame(minHeight: max(64, AppMetrics.minimumTouchTarget))
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSelectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .appSelectionScale(isActive: isSelected, reduceMotion: reduceMotion)
        .accessibilityLabel("Category \(category.name), \(isSelected ? "selected" : "not selected")")
    }

    private var bottomBar: some View {
        VStack(spacing: AppSpacing.stackItem) {
            Button(action: startTriviaTapped) {
                Text(playMode == .partyMode ? "Start Party Mode" : "Start Trivia")
            }
            .buttonStyle(.appPrimary)
            .disabled(!isStartEnabled)
        }
    }

    // MARK: - Actions

    private func toggleSelection(for id: UUID) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
            showCategoryUpgradeHint = false
            if selectedCategoryIDs.count != 1 { narrowToSingleCategory = false }
        } else if featureGates.canSelectAdditionalCategories(currentCount: selectedCategoryIDs.count) {
            selectedCategoryIDs.insert(id)
            showCategoryUpgradeHint = false
        } else {
            showCategoryUpgradeHint = true
        }
    }

    private func startTriviaTapped() {
        let names = effectiveCategoryNames
        analytics.track(.categoriesSelected(count: names.count, categories: names))
        gameSession.beginRound(
            mode: playMode,
            mood: selectedMood,
            selectedCategoryNames: selectedCategories.map(\.name),
            narrowToSingleCategory: narrowToSingleCategory && selectedMood == .custom
        )
        featureGates.applyQuestionLimit(to: gameSession)
        analytics.track(.quizStarted(questionCount: gameSession.totalQuestions))
        onStartTrivia()
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView()
            .environmentObject(GameSession())
    }
}
