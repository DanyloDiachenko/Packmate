import SwiftUI

struct ActiveTripSkeletonCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "141A26"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .frame(width: 90, height: 22)
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 22, height: 22)
                }

                HStack(alignment: .bottom, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.13))
                            .frame(width: 170, height: 24)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 125, height: 14)

                        HStack {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 70, height: 12)
                            Spacer()
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 36, height: 12)
                        }
                        .padding(.top, 4)

                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 5)

                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 62, height: 22)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 54, height: 22)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 68, height: 22)
                        }
                        .padding(.top, 4)
                    }

                    Spacer()

                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)
                        .frame(width: 74, height: 74)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .skeletonPulse()
    }
}
