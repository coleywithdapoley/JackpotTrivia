//
//  CategorySelectionView.swift
//  JackpotTrivia
//

import SwiftUI

// MARK: - Model

struct TriviaCategory: Identifiable, Equatable {
    let id: UUID
    let name: String
    let emoji: String?
    let description: String?

    static let sampleCategories: [TriviaCategory] = {
        AppConfig.defaultCategories.map { name in
            TriviaCategory(
                id: UUID(),
                name: name,
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
    @State private var showPremiumUpgrade = false

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
                    .padding(.top, AppSpacing.section)

                moodSection
                    .padding(.top, AppSpacing.section)

                if playMode == .chooseCategories, selectedMood == .custom {
                    categoryList
                        .padding(.top, AppSpacing.section)

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
        .background(Color(.systemBackground))
        .sheet(isPresented: $showInviteFriends) {
            InviteFriendsSheet()
        }
        .premiumUpgradeSheet(isPresented: $showPremiumUpgrade)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPremiumUpgrade = true
                } label: {
                    Image(systemName: "crown.fill")
                }
                .accessibilityLabel("Premium")
                .accessibilityHint("Opens the Premium upgrade screen")
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
                .appScreenHorizontalPadding()
                .padding(.top, AppSpacing.bottomBarTop)
                .padding(.bottom, AppSpacing.screenBottom)
                .background(Color(.systemBackground))
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
                    .foregroundStyle(isSelected ? AppColors.royalBlue : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(mode.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColors.royalBlue : Color(.tertiaryLabel))
            }
            .padding(AppSpacing.cardInnerHorizontal)
            .frame(minHeight: AppMetrics.minimumTouchTarget)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColors.royalBlue.opacity(0.1) : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.royalBlue : AppColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
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
                .appCaptionText()
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
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minWidth: 88, minHeight: AppMetrics.minimumTouchTarget)
            .background(isSelected ? AppColors.royalBlue : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.royalBlue : AppColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood \(mood.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var categoryList: some View {
        LazyVStack(spacing: AppSpacing.stackItem) {
            ForEach(categories) { category in
                categoryRow(category)
            }
        }
    }

    private var narrowCategoryToggle: some View {
        Toggle("Advanced: focus on one category only", isOn: $narrowToSingleCategory)
            .font(.subheadline)
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
            Text("Free tier: up to \(featureGates.maxCategoriesSelectable) categories per round.")
                .appCaptionText()
        }

        if showCategoryUpgradeHint {
            Button {
                showPremiumUpgrade = true
            } label: {
                Label("Upgrade to unlock more categories", systemImage: "crown.fill")
                    .font(.footnote)
                    .foregroundStyle(AppColors.royalBlue)
            }
        }
    }

    private var comfortLink: some View {
        NavigationLink {
            ComfortPreferencesView()
        } label: {
            Label("Comfort & content filters", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .foregroundStyle(AppColors.royalBlue)
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
                .foregroundStyle(AppColors.royalBlue)
            }
        }
    }

    private func categoryRow(_ category: TriviaCategory) -> some View {
        let isSelected = selectedCategoryIDs.contains(category.id)

        return Button {
            toggleSelection(for: category.id)
        } label: {
            HStack(spacing: 14) {
                if let emoji = category.emoji {
                    Text(emoji)
                        .font(.title2)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    if let description = category.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppColors.royalBlue : Color(.tertiaryLabel))
            }
            .padding(.horizontal, AppSpacing.cardInnerHorizontal)
            .padding(.vertical, AppSpacing.cardInnerVertical)
            .frame(minHeight: max(56, AppMetrics.minimumTouchTarget))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColors.royalBlue.opacity(0.1) : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.royalBlue : AppColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
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
