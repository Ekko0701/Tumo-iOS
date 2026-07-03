import ComposableArchitecture
import OrderFeature
import StockFeature
import XCTest
@testable import HomeFeature

@MainActor
final class HomeFeatureTests: XCTestCase {
    private func portfolio() -> Portfolio {
        Portfolio(cashBalance: 9_250_000, totalStockValue: 750_000, totalAsset: 10_000_000,
                  profitAmount: 50_000, profitRate: 0.5,
                  holdings: [StockHolding(stockCode: "005930", stockName: "삼성전자", quantity: 10,
                                          averagePrice: 70_000, currentPrice: 75_000, evaluationAmount: 750_000,
                                          profitAmount: 50_000, profitRate: 7.1)])
    }
    private func mover(_ code: String) -> Stock {
        Stock(stockCode: code, stockName: "종목\(code)", market: "KOSPI", currentPrice: 75_000,
              changePrice: 2_000, changeRate: Decimal(string: "2.74"), tradeVolume: 1, tradeAmount: 1,
              priceChangedAt: "2026-07-03T10:00:00")
    }
    private func order(_ id: Int) -> OrderHistoryItem {
        OrderHistoryItem(orderId: id, stockCode: "005930", stockName: "삼성전자", orderType: "BUY",
                         quantity: 4, executedPrice: 80_000, totalAmount: 320_000, realizedProfit: nil,
                         executedAt: "2026-07-03T10:00:00")
    }

    func test_onAppear_loadsDashboard() async {
        let p = portfolio(); let movers = [mover("005930"), mover("000660")]; let orders = [order(1), order(2)]
        let store = TestStore(initialState: HomeFeature.State()) { HomeFeature() }
        store.dependencies.stockClient.fetchPortfolio = { p }
        store.dependencies.stockClient.fetchStockRankings = { _, _, _, _ in
            StockPage(stocks: movers, page: 0, hasNext: false)
        }
        store.dependencies.orderClient.history = { _, _ in OrderPage(items: orders, page: 0, hasNext: false) }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.dataLoaded(p, movers, orders)) {
            $0.isLoading = false
            $0.portfolio = p
            $0.topMovers = movers
            $0.recentOrders = orders
        }
    }

    func test_onAppear_failureSetsError() async {
        struct Boom: Error {}
        let store = TestStore(initialState: HomeFeature.State()) { HomeFeature() }
        store.dependencies.stockClient.fetchPortfolio = { throw Boom() }
        store.dependencies.stockClient.fetchStockRankings = { _, _, _, _ in StockPage(stocks: [], page: 0, hasNext: false) }
        store.dependencies.orderClient.history = { _, _ in OrderPage(items: [], page: 0, hasNext: false) }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "홈 정보를 불러오지 못했습니다."
        }
    }

    func test_stockTapped_presentsDetail() async {
        let stock = mover("005930")
        let store = TestStore(initialState: HomeFeature.State()) { HomeFeature() }
        await store.send(.stockTapped(stock)) {
            $0.stockDetail = StockDetailFeature.State(stock: stock)
        }
    }
}
