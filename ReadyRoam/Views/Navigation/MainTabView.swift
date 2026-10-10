import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case myTrips = 0
    case archivedTrips = 1
    case settings = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .myTrips: return "My Trips"
        case .archivedTrips: return "Archive"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .myTrips: return "suitcase.fill"
        case .archivedTrips: return "archivebox.fill"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    var onLogout: (() -> Void)? = nil

    @EnvironmentObject private var router: AppRouter
    private let fabMargin: CGFloat = 11

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                NavigationStack(path: $router.myTripsPath) {
                    MyTripsView(
                        onOpenSettings: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                router.selectedTab = .settings
                            }
                        }
                    )
                }
                .opacity(router.selectedTab == .myTrips ? 1 : 0)
                .allowsHitTesting(router.selectedTab == .myTrips)

                NavigationStack(path: $router.archivePath) {
                    ArchivedTripsView(
                        onOpenSettings: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                router.selectedTab = .settings
                            }
                        }
                    )
                }
                .opacity(router.selectedTab == .archivedTrips ? 1 : 0)
                .allowsHitTesting(router.selectedTab == .archivedTrips)

                SettingsView(
                    onLogout: onLogout,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            router.selectedTab = .myTrips
                        }
                    }
                )
                .opacity(router.selectedTab == .settings ? 1 : 0)
                .allowsHitTesting(router.selectedTab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                if router.selectedTab == .myTrips && router.myTripsPath.isEmpty {
                    HStack {
                        Spacer()
                        newTripButton
                            .padding(.trailing, fabMargin)
                            .padding(.bottom, fabMargin)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                if router.myTripsPath.isEmpty && router.archivePath.isEmpty {
                    bottomTabBar
                }
            }

            DrawerOverlayMask(
                isShowing: router.isShowingNewTripDrawer,
                onTap: {
                    router.dismissNewTripDrawer()
                }
            )

            GeometryReader { geometry in
                SlidingDrawerContainer(
                    isShowing: router.isShowingNewTripDrawer,
                    height: geometry.size.height * 0.88,
                    dragOffset: $router.newTripDragOffset,
                    onDismiss: {
                        router.dismissNewTripDrawer()
                    },
                    onDragReset: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            router.newTripDragOffset = 0
                        }
                    }
                ) {
                    NewTripView(
                        onTripCreated: { _ in
                            router.dismissNewTripDrawer()
                            NotificationCenter.default.post(name: .didCreateNewTrip, object: nil)
                        },
                        onCancel: {
                            router.dismissNewTripDrawer()
                        },
                        dragOffset: $router.newTripDragOffset
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
    }

    private var newTripButton: some View {
        Button(action: {
            router.presentNewTripDrawer()
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
                        router.selectedTab = tab
                    }
                }) {
                    VStack(spacing: 5) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: router.selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(router.selectedTab == tab ? AppTheme.skyCyan : AppTheme.textMuted)

                        Text(tab.title)
                            .font(.system(size: 11, weight: router.selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(router.selectedTab == tab ? AppTheme.skyCyan : AppTheme.textMuted)
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
            .environmentObject(AppRouter())
    }
}
