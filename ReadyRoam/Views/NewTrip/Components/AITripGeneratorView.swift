import SwiftUI

struct AITripGeneratorView: View {
    @ObservedObject var viewModel: AITripGeneratorViewModel
    var onTripCreated: ((Trip) -> Void)? = nil

    @FocusState private var isPromptFocused: Bool

    var body: some View {
        VStack(spacing: 18) {
            promptInputCard

            if viewModel.isGenerating {
                skeletonTripLoadingCard
            } else if viewModel.hasSuccessfulSkeleton {
                skeletonPreviewSection
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isPromptFocused = false
        }
    }

    private var promptInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                if viewModel.hasSuccessfulSkeleton {
                    Text("✨")
                        .font(.system(size: 13))

                    Text("REFINE TRIP WITH AI")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(Color(hex: "E879F9"))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.skyCyan)

                    Text("DESCRIBE YOUR TRIP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.skyCyan)
                }

                Spacer()
            }

            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if viewModel.promptText.isEmpty {
                        Text(
                            viewModel.hasSuccessfulSkeleton
                                ? "Prompt AI to adjust destination, dates or packing items (e.g. 'pack for rainy weather', 'add gym gear')..."
                                : "e.g. 5 days in Budapest Nov 8-13 for business & sightseeing"
                        )
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.leading)
                        .padding(14)
                        .allowsHitTesting(false)
                    }

                    TextField("", text: $viewModel.promptText, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .focused($isPromptFocused)
                        .padding(14)
                }
                .frame(minHeight: 88, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isPromptFocused
                                        ? (viewModel.hasSuccessfulSkeleton ? Color(hex: "A855F7").opacity(0.8) : AppTheme.skyCyan.opacity(0.8))
                                        : AppTheme.inputBorder.opacity(0.6),
                                    lineWidth: 1
                                )
                        )
                )

                if !viewModel.promptText.isEmpty {
                    Button(action: {
                        viewModel.promptText = ""
                    }) {
                        Text("Clear")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            if let errorMsg = viewModel.errorMessage, !viewModel.isGenerating {
                inlineErrorFeedbackCard(message: errorMsg)
            } else if let successMsg = viewModel.successMessage, !viewModel.isGenerating {
                inlineSuccessFeedbackCard(message: successMsg)
            }

            if viewModel.hasSuccessfulSkeleton {
                if let actions = viewModel.generationResponse?.nextPossibleActions, !actions.isEmpty {
                    suggestedNextActionsSection(actions: actions)
                }
            } else {
                samplePromptsSection
            }

            Button(action: {
                isPromptFocused = false
                Task {
                    await viewModel.generateTrip()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "E879F9")))
                            .scaleEffect(0.9)
                        Text(viewModel.hasSuccessfulSkeleton ? "Updating Trip with AI..." : "Planning Trip with AI...")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "E879F9"))
                    } else {
                        Text("✨")
                            .font(.system(size: 14))
                        Text(viewModel.hasSuccessfulSkeleton ? "Update Trip with AI" : "Generate Trip with AI")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "E879F9"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "1F172E").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: "A855F7").opacity(0.55), lineWidth: 1.2)
                        )
                )
                .opacity(viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isGenerating ? 0.55 : 1.0)
            }
            .disabled(viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var samplePromptsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRY AN EXAMPLE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundColor(AppTheme.textMuted)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.samplePrompts, id: \.self) { sample in
                    Button(action: {
                        isPromptFocused = false
                        Task {
                            await viewModel.generateTrip(overridePrompt: sample)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("✨")
                                .font(.system(size: 11))

                            Text(sample)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "E879F9"))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "A855F7").opacity(0.7))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Capsule()
                                .fill(Color(hex: "1F172E").opacity(0.85))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "A855F7").opacity(0.55), lineWidth: 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isGenerating)
                    .opacity(viewModel.isGenerating ? 0.5 : 1.0)
                }
            }
        }
    }

    private func suggestedNextActionsSection(actions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("✨")
                    .font(.system(size: 12))

                Text("SUGGESTED NEXT ACTIONS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(Color(hex: "E879F9"))
            }

            VStack(spacing: 8) {
                ForEach(actions, id: \.self) { action in
                    Button(action: {
                        isPromptFocused = false
                        Task {
                            await viewModel.applyNextAction(action)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "E879F9"))

                            Text(action)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "F5D0FE"))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "A855F7").opacity(0.7))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Capsule()
                                .fill(Color(hex: "1F172E").opacity(0.85))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "A855F7").opacity(0.45), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isGenerating)
                    .opacity(viewModel.isGenerating ? 0.5 : 1.0)
                }
            }
        }
    }

    private var skeletonTripLoadingCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "1F2432"))
                    .frame(height: 150)
                    .overlay(
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 180, height: 22)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 130, height: 14)
                        }
                        .padding(14),
                        alignment: .bottomLeading
                    )

                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 220, height: 14)
                        .padding(.top, 12)

                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { _ in
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 60, height: 20)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.darkSurface)
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 140, height: 16)
                    Spacer()
                }

                VStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 18, height: 18)

                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                                    .frame(width: 130, height: 14)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 80, height: 10)
                            }

                            Spacer()

                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 50, height: 16)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "141822"))
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.darkSurface)
            )

            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .skeletonPulse()
    }

    private func inlineErrorFeedbackCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "EF4444"))

                Text("Error")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "EF4444"))

                Spacer()

                Button(action: {
                    viewModel.errorMessage = nil
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !viewModel.missingFields.isEmpty {
                HStack(spacing: 6) {
                    Text("Missing:")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)

                    ForEach(viewModel.missingFields, id: \.self) { field in
                        Text(field)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "EF4444").opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "271517"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "EF4444").opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func inlineSuccessFeedbackCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("✨")
                    .font(.system(size: 13))

                Text("AI Update")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "E879F9"))

                Spacer()

                Button(action: {
                    viewModel.successMessage = nil
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "F5D0FE"))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "1F172E").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "A855F7").opacity(0.5), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var skeletonPreviewSection: some View {
        if let skel = viewModel.skeleton {
            VStack(spacing: 16) {
                heroCard(skel: skel)

                itemsSection(items: viewModel.editableItems)

                createTripActionButton(skel: skel)
            }
        }
    }

    private func heroCard(skel: TripSkeletonDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let banner = skel.bannerImage, let url = URL(string: banner) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            fallbackBannerBackground
                        }
                    }
                    .frame(height: 150)
                    .clipped()
                } else {
                    fallbackBannerBackground
                        .frame(height: 120)
                }

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if let flag = skel.countryFlag, !flag.isEmpty {
                            Text(flag)
                                .font(.system(size: 22))
                        }

                        Text("\(skel.city), \(skel.country)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(skel.departDate) → \(skel.returnDate)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.white.opacity(0.9))

                        Text("•")
                            .foregroundColor(.white.opacity(0.6))

                        Text("\(skel.durationDays) days")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.skyCyan)
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                if let weather = skel.weatherSummary, !weather.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "F59E0B"))

                        VStack(alignment: .leading, spacing: 2) {
                            if let season = skel.currentSeason, !season.isEmpty {
                                Text(season.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .tracking(1.0)
                                    .foregroundColor(Color(hex: "F59E0B"))
                            }

                            Text(weather)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.top, 12)
                }

                if !skel.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(skel.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.skyCyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.skyCyan.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var fallbackBannerBackground: some View {
        LinearGradient(
            colors: [Color(hex: "1E293B"), Color(hex: "0F172A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func itemsSection(items: [AISkeletonItemDto]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CURATED ITEMS (\(viewModel.selectedItemsCount)/\(items.count))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.skyCyan)

                Spacer()

                Button(action: {
                    if viewModel.selectedItemsCount == items.count {
                        viewModel.deselectAllItems()
                    } else {
                        viewModel.selectAllItems()
                    }
                }) {
                    Text(viewModel.selectedItemsCount == items.count ? "Deselect All" : "Select All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            VStack(spacing: 8) {
                ForEach(items) { item in
                    itemRow(item: item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func itemRow(item: AISkeletonItemDto) -> some View {
        let isSelected = viewModel.selectedItemIds.contains(item.id)
        let categoryInfo = ChecklistCategory.categoryInfo(for: item.section)
        let tagColor = ItemTag(rawValue: (item.tag ?? "Essential").capitalized)?.tagColor ?? AppTheme.skyCyan

        return Button(action: {
            viewModel.toggleItem(item.id)
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? AppTheme.skyCyan : AppTheme.textMuted)

                if let emoji = item.iconEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textMuted)

                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        if let tag = item.tag, !tag.isEmpty {
                            Text(tag.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(tagColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tagColor.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    if let reason = item.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Text(categoryInfo.title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(categoryInfo.color.opacity(0.8))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color(hex: "1F2432") : Color(hex: "141822"))
            )
        }
        .buttonStyle(.plain)
    }

    private func createTripActionButton(skel: TripSkeletonDto) -> some View {
        Button(action: {
            Task {
                await viewModel.confirmAndCreateTrip { createdTrip in
                    onTripCreated?(createdTrip)
                }
            }
        }) {
            HStack(spacing: 8) {
                if viewModel.isCreatingTrip {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                    Text("Creating Trip...")
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Create Trip with AI (\(viewModel.selectedItemsCount) items)")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .disabled(viewModel.isCreatingTrip)
    }
}
