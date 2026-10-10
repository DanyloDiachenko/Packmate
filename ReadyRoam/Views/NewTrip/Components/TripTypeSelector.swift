import SwiftUI

struct TripTypeSelector: View {
    @Binding var selectedTripTypes: Set<NewTripType>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TRIP TYPE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.textMuted)

                Spacer()

                if !selectedTripTypes.isEmpty {
                    Text("\(selectedTripTypes.count) selected")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.skyCyan)
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(NewTripType.allCases) { type in
                    tripTypePill(type: type)
                }
            }
        }
    }

    private func tripTypePill(type: NewTripType) -> some View {
        let isSelected = selectedTripTypes.contains(type)

        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                if isSelected {
                    selectedTripTypes.remove(type)
                } else {
                    selectedTripTypes.insert(type)
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.skyCyan)

                Text(type.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color(hex: "1F2432"), Color(hex: "1A1F2C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isSelected ? Color.clear : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.electricBlue.opacity(0.4) : Color.clear,
                radius: 8,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(.plain)
    }
}
