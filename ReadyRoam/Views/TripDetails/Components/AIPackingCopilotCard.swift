import SwiftUI

struct AIPackingCopilotCard: View {
    @ObservedObject var viewModel: AIPackingCopilotViewModel
    @ObservedObject var tripDetailsViewModel: TripDetailsViewModel

    @FocusState private var isPromptFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            if !viewModel.hasActiveProposedChanges {
                presetsSection
                promptInputSection
            }

            if let errorMsg = viewModel.errorMessage, !viewModel.isRefining {
                errorNoticeCard(message: errorMsg)
            }

            if let appliedMsg = viewModel.appliedSuccessNotice, !viewModel.isRefining && !viewModel.hasActiveProposedChanges {
                appliedNoticeCard(message: appliedMsg)
            }

            if viewModel.isRefining {
                loadingRefiningCard
            } else if viewModel.hasActiveProposedChanges {
                proposedChangesSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "131020").opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "A855F7").opacity(0.55), Color(hex: "6366F1").opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color(hex: "A855F7").opacity(0.12), radius: 14, x: 0, y: 4)
        )
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "E879F9"))

            Text("AI PACKING COPILOT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.3)
                .foregroundColor(Color(hex: "E879F9"))

            Spacer()

            Text("Ask AI")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "F5D0FE"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(hex: "3B185F").opacity(0.8))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "C084FC").opacity(0.4), lineWidth: 1)
                        )
                )
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.isShowingDynamicNextActions ? "SUGGESTED NEXT ACTIONS" : "QUICK REFINEMENTS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundColor(viewModel.isShowingDynamicNextActions ? Color(hex: "C084FC") : AppTheme.textMuted)

                Spacer()

                if viewModel.isShowingDynamicNextActions {
                    Button(action: {
                        viewModel.resetToDefaultPresets()
                    }) {
                        Text("Reset to default")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(viewModel.displayedQuickRefinements, id: \.self) { prompt in
                    Button(action: {
                        isPromptFocused = false
                        Task {
                            await viewModel.refinePacking(promptOverride: prompt, tripDetailsViewModel: tripDetailsViewModel)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(presetEmoji(for: prompt))
                                .font(.system(size: 13))

                            Text(prompt)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "F5D0FE"))
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "C084FC").opacity(0.7))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "1F172E").opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(hex: "A855F7").opacity(0.35), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isRefining)
                }
            }
        }
    }

    private func presetEmoji(for prompt: String) -> String {
        let p = prompt.lowercased()
        if p.contains("hike") { return "🥾" }
        if p.contains("remove") { return "✂️" }
        if p.contains("laundry") { return "🧺" }
        if p.contains("carry-on") { return "🧳" }
        if p.contains("missing") { return "🔍" }
        if p.contains("lighter") { return "🪶" }
        return "✨"
    }

    private var promptInputSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if viewModel.promptText.isEmpty {
                    Text("Or type custom instructions (e.g. 'pack for rainy weather', 'cut down clothes')...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(12)
                        .allowsHitTesting(false)
                }

                TextField("", text: $viewModel.promptText, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .focused($isPromptFocused)
                    .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.inputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isPromptFocused ? Color(hex: "A855F7").opacity(0.8) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )

            HStack {
                if !viewModel.promptText.isEmpty {
                    Button(action: {
                        viewModel.promptText = ""
                    }) {
                        Text("Clear")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }

                Spacer()

                Button(action: {
                    isPromptFocused = false
                    Task {
                        await viewModel.refinePacking(tripDetailsViewModel: tripDetailsViewModel)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                        Text("Ask Copilot")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "9333EA"), Color(hex: "6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .disabled(viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isRefining)
                .opacity(viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
        }
    }

    private var loadingRefiningCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "E879F9")))
                .scaleEffect(0.9)

            Text("Copilot is analyzing and refining items...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "F5D0FE"))

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "1F172E").opacity(0.85))
        )
    }

    private var proposedChangesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let resp = viewModel.copilotResponse, let exp = resp.explanation {
                HStack(alignment: .top, spacing: 8) {
                    Text("✨")
                        .font(.system(size: 14))

                    Text(exp)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "F5D0FE"))
                        .lineSpacing(2)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "1F172E").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(hex: "A855F7").opacity(0.35), lineWidth: 1)
                        )
                )
            }

            if let additions = viewModel.copilotResponse?.additions, !additions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS TO ADD")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(Color(hex: "10B981"))

                    ForEach(additions) { item in
                        additionRow(item: item)
                    }
                }
            }

            if let removals = viewModel.copilotResponse?.removals, !removals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS TO REMOVE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(Color(hex: "EF4444"))

                    ForEach(removals) { item in
                        removalRow(item: item)
                    }
                }
            }

            if let modifications = viewModel.copilotResponse?.modifications, !modifications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS TO ADJUST")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(Color(hex: "F59E0B"))

                    ForEach(modifications) { item in
                        modificationRow(item: item)
                    }
                }
            }

            if let actions = viewModel.copilotResponse?.nextActions, !actions.isEmpty {
                nextActionsSection(actions: actions)
            }

            HStack(spacing: 10) {
                Button(action: {
                    Task {
                        await viewModel.applySelectedChanges(tripDetailsViewModel: tripDetailsViewModel)
                    }
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isApplyingChanges {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                        }

                        Text("Apply \(viewModel.totalSelectedChangesCount) Changes")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "9333EA"), Color(hex: "6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(viewModel.totalSelectedChangesCount == 0 || viewModel.isApplyingChanges)
                .opacity(viewModel.totalSelectedChangesCount == 0 ? 0.45 : 1)

                Button(action: {
                    viewModel.discardProposedChanges()
                }) {
                    Text("Discard")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: 80, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                }
            }
            .padding(.top, 4)
        }
    }

    private func additionRow(item: AICopilotItemAdditionDto) -> some View {
        let isSelected = viewModel.selectedAdditionIds.contains(item.id)
        return Button(action: {
            viewModel.toggleAddition(item.id)
        }) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "10B981") : AppTheme.textMuted)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("\(item.quantity)x")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color(hex: "10B981").opacity(0.15))
                            .clipShape(Capsule())

                        Spacer()

                        Text(item.section)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }

                    if let r = item.reason {
                        Text(r)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "10B981").opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    private func removalRow(item: AICopilotItemRemovalDto) -> some View {
        let isSelected = viewModel.selectedRemovalIds.contains(item.id)
        return Button(action: {
            viewModel.toggleRemoval(item.id)
        }) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "EF4444") : AppTheme.textMuted)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Text(item.section)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }

                    if let r = item.reason {
                        Text(r)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "EF4444").opacity(0.85))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "EF4444").opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    private func modificationRow(item: AICopilotItemModificationDto) -> some View {
        let isSelected = viewModel.selectedModificationIds.contains(item.id)
        return Button(action: {
            viewModel.toggleModification(item.id)
        }) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "F59E0B") : AppTheme.textMuted)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        if let cur = item.currentQuantity {
                            Text("\(cur)x → \(item.newQuantity)x")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color(hex: "F59E0B").opacity(0.15))
                                .clipShape(Capsule())
                        } else {
                            Text("\(item.newQuantity)x")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color(hex: "F59E0B").opacity(0.15))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Text(item.section)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }

                    if let r = item.reason {
                        Text(r)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "F59E0B").opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    private func nextActionsSection(actions: [String]) -> some View {
        let capped = Array(actions.prefix(3))
        return VStack(alignment: .leading, spacing: 6) {
            Text("SUGGESTED NEXT ACTIONS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(Color(hex: "C084FC"))

            VStack(spacing: 6) {
                ForEach(capped, id: \.self) { act in
                    Button(action: {
                        Task {
                            await viewModel.refinePacking(promptOverride: act, tripDetailsViewModel: tripDetailsViewModel)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "E879F9"))

                            Text(act)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "F5D0FE"))

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "C084FC"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: "1F172E").opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color(hex: "A855F7").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isRefining)
                }
            }
        }
        .padding(.top, 4)
    }

    private func errorNoticeCard(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "EF4444"))

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "EF4444"))

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "EF4444").opacity(0.12))
        )
    }

    private func appliedNoticeCard(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "10B981"))

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "10B981"))

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "10B981").opacity(0.12))
        )
    }
}
