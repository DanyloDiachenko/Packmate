import SwiftUI

struct AICopilotDrawer: View {
    @ObservedObject var viewModel: AIPackingCopilotViewModel
    @ObservedObject var tripDetailsViewModel: TripDetailsViewModel
    var onClose: (() -> Void)? = nil

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
                    AIPackingCopilotCard(
                        viewModel: viewModel,
                        tripDetailsViewModel: tripDetailsViewModel
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                }
            }
        }
    }

    private var drawerHeader: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "A855F7"), Color(hex: "6366F1")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("AI Packing Copilot")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
    }
}
