import SwiftUI

struct AISuggestionsDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AISuggestionsViewModel
    var onClose: (() -> Void)? = nil

    init(
        cityName: String = "",
        country: String = "",
        season: String = "",
        temperature: String = "",
        tripDays: Int = 0,
        tripType: String = "",
        existingItems: [String] = [],
        onAddItem: ((AISuggestion) -> Void)? = nil,
        onRemoveItem: ((AISuggestion) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: AISuggestionsViewModel(
            cityName: cityName,
            country: country,
            season: season,
            temperature: temperature,
            tripDays: tripDays,
            tripType: tripType,
            existingItems: existingItems,
            onAddItem: onAddItem,
            onRemoveItem: onRemoveItem
        ))
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(hex: "3A3F4D"))
                    .frame(width: 36, height: 4.5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                drawerHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if viewModel.isLoading && viewModel.suggestions.isEmpty {
                            ForEach(0..<4, id: \.self) { _ in
                                skeletonCard
                            }
                        } else if viewModel.hasError && viewModel.suggestions.isEmpty {
                            retryView
                        } else {
                            ForEach($viewModel.suggestions) { $suggestion in
                                suggestionCard(suggestion: $suggestion)
                            }

                            generateMoreButton
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 0)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadSuggestions(appending: false)
        }
    }

    private var drawerHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Text("✨")
                        .font(.system(size: 20))

                    Text("AI Suggestions")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                Button(action: {
                    if let onClose = onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }

            Text(viewModel.headerSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var skeletonCard: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "1F2432"))
                .frame(width: 46, height: 46)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "2A2F3D"))
                    .frame(height: 14)
                    .frame(maxWidth: 160)
                    .shimmer()

                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: "2A2F3D"))
                    .frame(height: 11)
                    .frame(maxWidth: 220)
                    .shimmer()

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(hex: "2A2F3D"))
                        .frame(width: 80, height: 20)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(hex: "2A2F3D"))
                        .frame(width: 60, height: 20)
                        .shimmer()
                }
                .padding(.top, 2)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 17)
                .fill(Color(hex: "2A2F3D"))
                .frame(width: 82, height: 34)
                .shimmer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "181C26"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var retryView: some View {
        VStack(spacing: 16) {
            Text("🤖")
                .font(.system(size: 44))

            VStack(spacing: 6) {
                Text("AI is taking a break")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("The service is experiencing high demand.\nPlease try again in a moment.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: {
                Task { await viewModel.loadSuggestions(appending: false) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Try Again")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(Color(hex: "E879F9"))
                .padding(.horizontal, 24)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: "1F172E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color(hex: "A855F7").opacity(0.55), lineWidth: 1.2)
                        )
                )
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    private func suggestionCard(suggestion: Binding<AISuggestion>) -> some View {
        let item = suggestion.wrappedValue

        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "1F2432"))
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                Text(item.iconEmoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(item.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    sectionTagBadge(title: item.sectionTitle, color: item.sectionAccentColor)
                    importanceTagBadge(tag: item.importance)
                }
                .padding(.top, 2)
            }

            Spacer()

            Button(action: {
                viewModel.toggleSuggestion(item)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: item.isAdded ? "checkmark" : "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(item.isAdded ? "Added" : "Add")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: 82, height: 34)
                .background(
                    item.isAdded ?
                        LinearGradient(colors: [Color(hex: "0D9488"), Color(hex: "059669")], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color(hex: "0284C7"), Color(hex: "2563EB")], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(17)
                .shadow(
                    color: item.isAdded ? Color.clear : AppTheme.electricBlue.opacity(0.5),
                    radius: 8,
                    x: 0,
                    y: 3
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "181C26"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func sectionTagBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.18))
            .cornerRadius(7)
    }

    private func importanceTagBadge(tag: ItemTag) -> some View {
        HStack(spacing: 3.5) {
            if let icon = tag.iconName {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(tag.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(tag.tagColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(tag.backgroundColor)
        .cornerRadius(7)
    }

    private var generateMoreButton: some View {
        Button(action: {
            Task {
                await viewModel.loadSuggestions(appending: true)
            }
        }) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "E879F9"))
                } else {
                    Text("✨")
                        .font(.system(size: 14))

                    Text("Generate More Suggestions")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(viewModel.isLoading ? Color(hex: "E879F9").opacity(0.4) : Color(hex: "E879F9"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color(hex: "1F172E").opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(Color(hex: "A855F7").opacity(viewModel.isLoading ? 0.2 : 0.55), lineWidth: 1.2)
                    )
            )
        }
        .disabled(viewModel.isLoading)
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.08), location: 0.4),
                            .init(color: Color.white.opacity(0.12), location: 0.5),
                            .init(color: Color.white.opacity(0.08), location: 0.6),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint: .init(x: phase + 0.5, y: 0.5)
                    )
                    .blendMode(.plusLighter)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct AISuggestionsDrawer_Previews: PreviewProvider {
    static var previews: some View {
        AISuggestionsDrawer()
    }
}
