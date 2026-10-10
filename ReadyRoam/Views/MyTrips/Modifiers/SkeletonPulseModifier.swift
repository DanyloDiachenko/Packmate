import SwiftUI

struct SkeletonPulseModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.9 : 0.35)
            .animation(
                .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func skeletonPulse() -> some View {
        modifier(SkeletonPulseModifier())
    }
}
