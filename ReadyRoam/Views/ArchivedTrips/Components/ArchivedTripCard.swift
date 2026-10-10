import SwiftUI

struct ArchivedTripCard: View {
    let trip: Trip
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.darkBackground)
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    Text(trip.flagEmoji)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(trip.destination), \(trip.country)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        Text("ARCHIVED")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(4)
                    }

                    Text("\(trip.dateRange) · \(trip.nightsCount) nights")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    if !trip.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(trip.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.skyCyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.skyCyan.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.darkSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
