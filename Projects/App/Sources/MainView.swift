import SwiftUI

struct MainView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    MainTabContentView(tab: tab)
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

    var body: some View {
        ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(tab.title)
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(Color.tumoInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Spacer()

                Text("Tumo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tumoBlue)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Color {
    static let tumoBlue = Color(red: 0, green: 82.0 / 255.0, blue: 1)
    static let tumoInk = Color(red: 10.0 / 255.0, green: 11.0 / 255.0, blue: 13.0 / 255.0)
    static let tumoCanvas = Color.white
}

#Preview {
    MainView()
}
