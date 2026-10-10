import SwiftUI

struct TripDetailsHeaderView: View {
    let flagEmoji: String
    let city: String
    let dateRange: String
    let nightsCount: Int
    let isReadOnly: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isReadOnly ? "Archived Trips" : "My Trips")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundColor(AppTheme.skyCyan)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 10) {
                    Text(flagEmoji)
                        .font(.system(size: 28))
                    Text(city)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Text("\(dateRange) · \(nightsCount) nights")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

struct WeatherProgressCardView: View {
    let isLoadingWeather: Bool
    let hasWeatherInfo: Bool
    let weatherIconDisplay: String
    let temperatureDisplay: String
    let weatherSeasonDisplay: String
    let totalPacked: Int
    let totalItems: Int
    let overallProgress: Double

    var body: some View {
        HStack(spacing: 16) {
            if isLoadingWeather && !hasWeatherInfo {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 52, height: 14)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 38, height: 10)
                    }
                }
                .redacted(reason: .placeholder)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 42)
            } else if hasWeatherInfo {
                HStack(spacing: 10) {
                    Text(weatherIconDisplay)
                        .font(.system(size: 26))

                    VStack(alignment: .leading, spacing: 2) {
                        if !temperatureDisplay.isEmpty {
                            Text(temperatureDisplay)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                        }

                        if !weatherSeasonDisplay.isEmpty {
                            Text(weatherSeasonDisplay)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .lineLimit(1)
                        }
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 42)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Packed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text("\(totalPacked) / \(totalItems)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "232938"))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0284C7"), Color(hex: "38BDF8")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(overallProgress)), height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: overallProgress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct CircularGaugeView: View {
    let percentage: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3.5)
                .frame(width: 38, height: 38)

            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 38, height: 38)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: percentage)

            Text("\(percentage)%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(percentage > 0 ? AppTheme.textPrimary : AppTheme.textMuted)
        }
    }
}

struct TripDetailsBottomBarView: View {
    let onOpenAI: () -> Void
    let onOpenAddItem: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpenAI) {
                HStack(spacing: 8) {
                    Text("✨")
                        .font(.system(size: 14))

                    Text("AI Suggestions")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "E879F9"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color(hex: "1F172E").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .stroke(Color(hex: "A855F7").opacity(0.55), lineWidth: 1.2)
                        )
                )
            }

            Button(action: onOpenAddItem) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))

                    Text("Add Item")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(25)
                )
                .shadow(color: AppTheme.electricBlue.opacity(0.6), radius: 14, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 82)
        .background(
            LinearGradient(
                colors: [Color.clear, AppTheme.darkBackground.opacity(0.8), AppTheme.darkBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
