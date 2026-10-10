import SwiftUI

struct ActiveTripCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

                HStack {

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "22C55E"))
                            .frame(width: 7, height: 7)
                        Text("ACTIVE TRIP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.7))
                    .cornerRadius(20)

                    Spacer()

                    Text(trip.daysUntilText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FDE047"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.7))
                        .cornerRadius(20)
                }

                Spacer()
                    .frame(height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(trip.flagEmoji)
                            .font(.system(size: 24))
                        Text("\(trip.destination), \(trip.country)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("\(trip.dateRange) · \(trip.nightsCount) nights")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                }

                Spacer()
                    .frame(height: 8)

                HStack(alignment: .bottom, spacing: 16) {

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Packing progress")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.85))

                            Spacer()

                            Text("\(trip.packedItems) / \(trip.totalItems)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 5)

                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: max(0, geo.size.width * CGFloat(trip.progress)), height: 5)
                            }
                        }
                        .frame(height: 5)

                        if !trip.tags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(trip.tags, id: \.self) { tag in
                                    categoryTag(icon: TagHelper.icon(for: tag), text: tag.capitalized)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    ZStack {

                        Circle()
                            .trim(from: 0.15, to: 0.85)
                            .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(90))
                            .frame(width: 74, height: 74)

                        Circle()
                            .trim(from: 0.15, to: 0.15 + (0.7 * CGFloat(trip.progress)))
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(90))
                            .frame(width: 74, height: 74)

                        VStack(spacing: 1) {
                            Text("\(trip.packingPercentage)%")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("packed")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: AppTheme.electricBlue.opacity(0.3), radius: 18, x: 0, y: 8)
        }

    private var cardBackground: some View {
        GeometryReader { geo in
            ZStack {

                scenicBackground

                let bannerUrlString = (trip.bannerImage?.isEmpty == false) ? trip.bannerImage : nil

                if let bannerStr = bannerUrlString, let url = URL(string: bannerStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        case .failure:
                            EmptyView()
                        case .empty:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.42),
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    private var scenicBackground: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color(hex: "0284C7"),
                    Color(hex: "0369A1"),
                    Color(hex: "1E3A8A"),
                    Color(hex: "0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(hex: "FDE047").opacity(0.35), Color.clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 180
            )

            RadialGradient(
                colors: [Color(hex: "38BDF8").opacity(0.4), Color.clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 220
            )

            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear, Color.black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func categoryTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(Color.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.25))
        .cornerRadius(8)
    }
}
