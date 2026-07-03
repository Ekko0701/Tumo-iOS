import CoreDesignSystem
import HomeFeature
import MyInfoFeature
import OrderFeature
import StockFeature
import SwiftUI

struct MainView: View {
    let onLoggedOut: () -> Void
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    MainTabContentView(tab: tab, onLoggedOut: onLoggedOut)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .tint(.tumoBlue)
    }
}

private enum MainTab: String, CaseIterable, Identifiable {
    case home
    case stocks
    case orders
    case portfolio
    case my

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .home:
            "홈"
        case .stocks:
            "종목"
        case .orders:
            "주문"
        case .portfolio:
            "포트폴리오"
        case .my:
            "내 정보"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .stocks:
            "chart.line.uptrend.xyaxis"
        case .orders:
            "arrow.left.arrow.right"
        case .portfolio:
            "wallet.pass"
        case .my:
            "person.crop.circle"
        }
    }
}

private struct MainTabContentView: View {
    let tab: MainTab
    let onLoggedOut: () -> Void

    var body: some View {
        switch tab {
        case .home:
            HomeView()

        case .stocks:
            StockView()

        case .orders:
            OrderHistoryView()

        case .portfolio:
            PortfolioView()

        case .my:
            MyInfoView(onLoggedOut: onLoggedOut)
        }
    }
}

#Preview {
    MainView(onLoggedOut: {})
}
