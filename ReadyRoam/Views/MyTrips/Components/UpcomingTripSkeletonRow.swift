import SwiftUI

struct UpcomingTripSkeletonRow: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 140, height: 15)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 100, height: 12)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 64, height: 20)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 60, height: 12)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 8, height: 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .skeletonPulse()
    }
}
