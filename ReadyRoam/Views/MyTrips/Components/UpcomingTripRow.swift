import SwiftUI

struct UpcomingTripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 8) {
                    Text(trip.flagEmoji)
                        .font(.system(size: 20))

                    Text("\(trip.destination), \(trip.country)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(trip.daysUntilText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "FDE047"))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.7))
                }
            }

            Text(trip.dateRange)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            if !trip.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(trip.tags, id: \.self) { tag in
                        tagPill(icon: TagHelper.icon(for: tag), text: tag.capitalized)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func tagPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(Color(hex: "38BDF8"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "0369A1").opacity(0.35))
        .cornerRadius(8)
    }
}

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        var totalHeight: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        totalHeight = currentY + lineHeight
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

