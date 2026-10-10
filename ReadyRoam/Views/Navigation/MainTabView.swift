import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case myTrips = 0
    case archivedTrips = 1
    case newTrip = 2
    case settings = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .myTrips: return "My Trips"
        case .archivedTrips: return "Archive"
        case .newTrip: return "New Trip"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .myTrips: return "suitcase.fill"
        case .archivedTrips: return "archivebox.fill"
        case .newTrip: return "plus.circle.fill"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    var onLogout: (() -> Void)? = nil

    @State private var selectedTab: AppTab = .myTrips
    @State private var isViewingTripDetails: Bool = false
    @State private var isShowingAIDrawer: Bool = false
    @State private var upcomingTrips: [Trip] = []
    @State private var createdTrip: Trip? = nil

    private let fabMargin: CGFloat = 11

    var body: some View {
        ZStack(alignment: .bottom) {

            Group {
                switch selectedTab {
                case .myTrips:
                    NavigationStack {
                        MyTripsView(
                            isViewingTripDetails: $isViewingTripDetails,
                            isShowingAIDrawer: $isShowingAIDrawer,
                            upcomingTrips: $upcomingTrips,
                            createdTrip: $createdTrip,
                            onOpenSettings: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .settings
                                }
                            },
                            onPlanTrip: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedTab = .newTrip
                                }
                            }
                        )
                    }
                case .archivedTrips:
                    NavigationStack {
                        ArchivedTripsView(
                            isViewingTripDetails: $isViewingTripDetails,
                            onOpenSettings: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .settings
                                }
                            }
                        )
                    }
                case .newTrip:
                    NewTripView(
                        existingTrips: upcomingTrips,
                        onTripCreated: { newTrip in
                            createdTrip = newTrip
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTab = .myTrips
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = .myTrips
                            }
                        }
                    )
                case .settings:
                    SettingsView(
                        onLogout: onLogout,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = .myTrips
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                if selectedTab == .myTrips && !isViewingTripDetails {
                    HStack {
                        Spacer()
                        newTripButton
                            .padding(.trailing, fabMargin)
                            .padding(.bottom, fabMargin)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                bottomTabBar
                    .offset(y: isShowingAIDrawer ? 120 : 0)
                    .opacity(isShowingAIDrawer ? 0 : 1)
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
    }

    private var newTripButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = .newTrip
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "38BDF8"), Color(hex: "2563EB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.electricBlue.opacity(0.65), radius: 14, x: 0, y: 5)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private var bottomTabBar: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 5) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? AppTheme.skyCyan : AppTheme.textMuted)

                        Text(tab.title)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? AppTheme.skyCyan : AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(
            Color(hex: "0D111A")
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
