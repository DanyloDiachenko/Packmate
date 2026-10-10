import SwiftUI

struct DestinationSearchSection: View {
    @Binding var destinationText: String
    let isSearchActive: Bool
    let focusState: FocusState<Bool>.Binding
    let onClear: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DESTINATION")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)

                TextField(
                    "",
                    text: $destinationText,
                    prompt: Text("Search destination...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .focused(focusState)
                .autocorrectionDisabled()

                if !destinationText.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "181C26"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSearchActive ? AppTheme.skyCyan.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1.2)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
    }
}
