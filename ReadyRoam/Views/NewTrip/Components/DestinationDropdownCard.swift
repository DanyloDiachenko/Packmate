import SwiftUI

struct DestinationDropdownCard: View {
    let destinationText: String
    let isLoading: Bool
    let results: [DestinationDto]
    let onSelect: (DestinationDto) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "POPULAR DESTINATIONS" : "SEARCH RESULTS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.textMuted)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.skyCyan))
                        .scaleEffect(0.65)
                        .padding(.leading, 4)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .background(Color.white.opacity(0.06))

            ScrollView(showsIndicators: false) {
                if isLoading {
                    skeletonListView
                } else if results.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        Text("No destinations found")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(results) { item in
                            Button(action: {
                                onSelect(item)
                            }) {
                                HStack(spacing: 14) {
                                    Text(item.countryFlag)
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.city)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(AppTheme.textPrimary)

                                        Text(item.country)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if item.id != results.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.04))
                                    .padding(.leading, 50)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 240)
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "181C26"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 18, x: 0, y: 8)
        )
    }

    private var skeletonListView: some View {
        VStack(spacing: 0) {
            DestinationSkeletonRow(cityWidth: 105, countryWidth: 65)
            Divider().background(Color.white.opacity(0.04)).padding(.leading, 50)
            DestinationSkeletonRow(cityWidth: 130, countryWidth: 80)
            Divider().background(Color.white.opacity(0.04)).padding(.leading, 50)
            DestinationSkeletonRow(cityWidth: 90, countryWidth: 55)
            Divider().background(Color.white.opacity(0.04)).padding(.leading, 50)
            DestinationSkeletonRow(cityWidth: 115, countryWidth: 70)
        }
    }
}
