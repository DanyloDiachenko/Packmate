import SwiftUI

struct TripCalendarView: View {
    @Binding var dateSelection: TripDateSelection
    let blockedDates: Set<Date>
    let onDateTap: (Date) -> Void
    let onPrevMonth: () -> Void
    let onNextMonth: () -> Void

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHEN")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundColor(AppTheme.textMuted)

            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Depart")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)

                        Text(dateSelection.departBoxText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.skyCyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "1F2432"))
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Return")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)

                        Text(dateSelection.returnBoxText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.skyCyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "1F2432"))
                    )
                }

                HStack {
                    Text(dateSelection.monthHeaderTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 16) {
                        Button(action: onPrevMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(dateSelection.viewingMonthIndex > 0 ? AppTheme.skyCyan : AppTheme.textMuted.opacity(0.4))
                        }
                        .disabled(dateSelection.viewingMonthIndex == 0)

                        Button(action: onNextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(dateSelection.viewingMonthIndex < dateSelection.availableMonths.count - 1 ? AppTheme.skyCyan : AppTheme.textMuted.opacity(0.4))
                        }
                        .disabled(dateSelection.viewingMonthIndex == dateSelection.availableMonths.count - 1)
                    }
                }
                .padding(.top, 2)

                HStack {
                    ForEach(weekdays.indices, id: \.self) { idx in
                        Text(weekdays[idx])
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }

                calendarDaysGrid
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
    }

    private var calendarDaysGrid: some View {
        let cal = Calendar.current
        let month = dateSelection.currentViewingMonth
        let components = cal.dateComponents([.year, .month], from: month)
        let firstDayOfMonth = cal.date(from: components) ?? Date()
        let totalDays = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        let firstWeekday = cal.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayOffset = firstWeekday - 1

        return VStack(spacing: 6) {
            ForEach(0..<6) { week in
                HStack(spacing: 0) {
                    ForEach(0..<7) { dayOfWeek in
                        let dayNumber = week * 7 + dayOfWeek - firstWeekdayOffset + 1

                        if dayNumber >= 1 && dayNumber <= totalDays {
                            if let cellDate = cal.date(bySetting: .day, value: dayNumber, of: firstDayOfMonth) {
                                calendarDayCell(date: cal.startOfDay(for: cellDate), dayNumber: dayNumber)
                            } else {
                                emptyCell
                            }
                        } else {
                            emptyCell
                        }
                    }
                }
            }
        }
    }

    private var emptyCell: some View {
        Text("")
            .frame(maxWidth: .infinity)
            .frame(height: 36)
    }

    private func calendarDayCell(date: Date, dayNumber: Int) -> some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let isPast = date < today
        let isBlocked = blockedDates.contains(date)
        let isDepart = dateSelection.departDate != nil && cal.isDate(date, inSameDayAs: dateSelection.departDate!)
        let isReturn = dateSelection.returnDate != nil && cal.isDate(date, inSameDayAs: dateSelection.returnDate!)
        let isInRange: Bool = {
            guard let dep = dateSelection.departDate, let ret = dateSelection.returnDate else { return false }
            return date > dep && date < ret
        }()
        let circleSize: CGFloat = 32

        return Button(action: {
            onDateTap(date)
        }) {
            GeometryReader { geo in
                ZStack {
                    if isInRange {
                        Rectangle()
                            .fill(Color(hex: "0369A1").opacity(0.35))
                            .frame(width: geo.size.width, height: circleSize)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else if isDepart && dateSelection.returnDate != nil {
                        Rectangle()
                            .fill(Color(hex: "0369A1").opacity(0.35))
                            .frame(width: geo.size.width / 2, height: circleSize)
                            .position(x: geo.size.width * 0.75, y: geo.size.height / 2)
                    } else if isReturn && dateSelection.departDate != nil {
                        Rectangle()
                            .fill(Color(hex: "0369A1").opacity(0.35))
                            .frame(width: geo.size.width / 2, height: circleSize)
                            .position(x: geo.size.width * 0.25, y: geo.size.height / 2)
                    }

                    if isDepart || isReturn {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: circleSize, height: circleSize)
                            .shadow(color: Color(hex: "0284C7").opacity(0.55), radius: 6, x: 0, y: 2)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else if isBlocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: circleSize, height: circleSize)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }

                    VStack(spacing: 2) {
                        Text("\(dayNumber)")
                            .font(.system(size: 14, weight: (isDepart || isReturn) ? .bold : .medium))
                            .foregroundColor(
                                (isDepart || isReturn) ? .white :
                                isBlocked ? AppTheme.textMuted.opacity(0.35) :
                                isPast ? AppTheme.textMuted.opacity(0.25) :
                                isInRange ? Color(hex: "38BDF8") :
                                AppTheme.textPrimary
                            )

                        if isBlocked {
                            Circle()
                                .fill(Color(hex: "EF4444").opacity(0.6))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .frame(height: 36)
        }
        .disabled(isPast || isBlocked)
        .buttonStyle(.plain)
    }
}
