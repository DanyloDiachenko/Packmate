import SwiftUI

struct ChecklistCategoryCard: View {
    @Binding var category: ChecklistCategory
    let isExpanded: Bool
    let swipedItemId: UUID?
    let isReadOnly: Bool
    let onToggleExpand: () -> Void
    let onAddItem: () -> Void
    let onSwipeItem: (UUID, Bool) -> Void
    let onDeleteItem: (ChecklistItem) -> Void
    let onToggleItem: (ChecklistItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerButton

            if isExpanded {
                expandedContent
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var headerButton: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "1F2432"))
                        .frame(width: 42, height: 42)

                    Image(systemName: category.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(category.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("\(category.packedCount) of \(category.totalCount) items")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }

                Spacer()

                CircularGaugeView(percentage: category.percentage, color: category.accentColor)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.06))

            if category.items.isEmpty {
                emptyStateRow
            } else {
                itemsList
            }
        }
    }

    private var emptyStateRow: some View {
        HStack {
            Text("No items in this section yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
            Spacer()
            if !isReadOnly {
                Button(action: onAddItem) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Item")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(category.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(category.accentColor.opacity(0.12))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var itemsList: some View {
        ForEach($category.items) { $item in
            SwipeableChecklistItemRow(
                item: $item,
                sectionAccentColor: category.accentColor,
                isSwiped: swipedItemId == item.id,
                isReadOnly: isReadOnly,
                onSwipe: { isOpen in
                    onSwipeItem(item.id, isOpen)
                },
                onDelete: {
                    onDeleteItem(item)
                },
                onToggle: {
                    onToggleItem(item)
                }
            )

            if item.id != category.items.last?.id {
                Divider()
                    .background(Color.white.opacity(0.04))
                    .padding(.leading, 46)
            }
        }
    }
}
