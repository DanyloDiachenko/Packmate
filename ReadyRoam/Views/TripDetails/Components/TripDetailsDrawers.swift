import SwiftUI

struct SlidingDrawerContainer<Content: View>: View {
    let isShowing: Bool
    let height: CGFloat
    @Binding var dragOffset: CGFloat
    let dismissThreshold: CGFloat
    let onDismiss: () -> Void
    let onDragReset: () -> Void
    let content: Content

    init(
        isShowing: Bool,
        height: CGFloat,
        dragOffset: Binding<CGFloat>,
        dismissThreshold: CGFloat = 70,
        onDismiss: @escaping () -> Void,
        onDragReset: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isShowing = isShowing
        self.height = height
        self._dragOffset = dragOffset
        self.dismissThreshold = dismissThreshold
        self.onDismiss = onDismiss
        self.onDragReset = onDragReset
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                AppTheme.darkBackground
                    .clipShape(CustomCorners(radius: 24, corners: [.topLeft, .topRight]))
                    .overlay(
                        CustomCorners(radius: 24, corners: [.topLeft, .topRight])
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .ignoresSafeArea(edges: .bottom)
            )
            .offset(y: (isShowing ? 0 : height + 100) + max(0, dragOffset))
            .allowsHitTesting(isShowing)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > dismissThreshold {
                            onDismiss()
                        } else {
                            onDragReset()
                        }
                    }
            )
    }
}

struct DrawerOverlayMask: View {
    let isShowing: Bool
    let onTap: () -> Void

    var body: some View {
        Color.black.opacity(isShowing ? 0.52 : 0)
            .ignoresSafeArea()
            .allowsHitTesting(isShowing)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                onTap()
            }
    }
}
