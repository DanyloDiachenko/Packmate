import SwiftUI

struct SwipeableChecklistItemRow: View {
    @Binding var item: ChecklistItem
    var sectionAccentColor: Color
    var isSwiped: Bool
    var isReadOnly: Bool = false
    var onSwipe: (Bool) -> Void
    var onDelete: () -> Void
    var onToggle: (() -> Void)? = nil

    @State private var dragOffset: CGFloat = 0
    private let actionSize: CGFloat = 48

    var body: some View {
        let isRevealed = !isReadOnly && (isSwiped || dragOffset < 0)

        ZStack(alignment: .trailing) {

            if !isReadOnly {
                Button(action: {
                    onDelete()
                }) {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        Image(systemName: "trash.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: actionSize, height: actionSize)
                }
                .buttonStyle(.plain)
                .opacity(isRevealed ? 1 : 0)
                .allowsHitTesting(isSwiped)
            }

            HStack(spacing: 12) {

                ZStack {
                    if item.isPacked {
                        Circle()
                            .fill(sectionAccentColor)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Circle()
                            .stroke(AppTheme.inputBorder, lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                }

                Text(item.title)
                    .font(.system(size: 15, weight: item.isPacked ? .regular : .medium))
                    .foregroundColor(item.isPacked ? AppTheme.textMuted : AppTheme.textPrimary)

                Spacer()

                if let badge = item.countBadge {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }

                importanceTagBadge(tag: item.tag)
            }
            .padding(.horizontal, 16)
            .frame(height: actionSize)
            .background(Color(hex: "1C212E"))
            .contentShape(Rectangle())
            .offset(x: (!isReadOnly && isSwiped ? -actionSize : 0) + dragOffset)
            .gesture(
                isReadOnly ? nil :
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onChanged { value in
                        let translation = value.translation.width
                        if isSwiped {

                            if translation > 0 {
                                dragOffset = translation
                            } else {
                                dragOffset = translation * 0.25
                            }
                        } else {

                            if translation < 0 {
                                if translation < -actionSize {
                                    let excess = translation + actionSize
                                    dragOffset = -actionSize + (excess * 0.25)
                                } else {
                                    dragOffset = translation
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            if isSwiped {
                                if value.translation.width > 18 {
                                    onSwipe(false)
                                }
                            } else {
                                if value.translation.width < -18 {
                                    onSwipe(true)
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
            .onTapGesture {
                if !isReadOnly {
                    if isSwiped {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            onSwipe(false)
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            item.isPacked.toggle()
                        }
                        onToggle?()
                    }
                }
            }
        }
        .clipped()
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
}
