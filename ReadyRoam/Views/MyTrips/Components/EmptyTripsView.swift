import SwiftUI

struct EmptyTripsView: View {
    var onPlanTrip: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0284C7").opacity(0.2), Color(hex: "1E3A8A").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.skyCyan.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: AppTheme.electricBlue.opacity(0.25), radius: 16, x: 0, y: 6)

                Image(systemName: "suitcase.rolling.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.skyCyan)
            }
            .padding(.top, 40)

            VStack(spacing: 8) {
                Text("No Trips Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Your upcoming trips and packing lists will appear here. Plan your first journey now!")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                onPlanTrip?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Plan a Trip")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: AppTheme.electricBlue.opacity(0.4), radius: 12, x: 0, y: 4)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
