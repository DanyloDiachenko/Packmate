import SwiftUI

struct DestinationSkeletonRow: View {
    @State private var isAnimating: Bool = false
    let cityWidth: CGFloat
    let countryWidth: CGFloat

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(isAnimating ? 0.12 : 0.05))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(isAnimating ? 0.15 : 0.07))
                    .frame(width: cityWidth, height: 13)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(isAnimating ? 0.09 : 0.04))
                    .frame(width: countryWidth, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white.opacity(isAnimating ? 0.08 : 0.03))
                .frame(width: 7, height: 11)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}
