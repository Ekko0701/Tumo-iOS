import ComposableArchitecture
import StockFeature
import SwiftUI

@main
struct StockFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StockView(
                    store: Store(
                        initialState: StockFeature.State(stocks: Self.sampleStocks)
                    ) {
                        StockFeature()
                    }
                )
            }
        }
    }

    private static let sampleStocks: [Stock] = [
        Stock(stockCode: "005930", stockName: "삼성전자", market: "KOSPI", currentPrice: 75_000, priceChangedAt: "2026-05-13T15:30:00"),
        Stock(stockCode: "000660", stockName: "SK하이닉스", market: "KOSPI", currentPrice: 180_000, priceChangedAt: "2026-05-13T15:30:00"),
        Stock(stockCode: "035420", stockName: "NAVER", market: "KOSPI", currentPrice: 190_000, priceChangedAt: "2026-05-13T15:30:00"),
        Stock(stockCode: "035720", stockName: "카카오", market: "KOSDAQ", currentPrice: 55_000, priceChangedAt: "2026-05-13T15:30:00"),
        Stock(stockCode: "005380", stockName: "현대차", market: "KOSPI", currentPrice: 245_000, priceChangedAt: "2026-05-13T15:30:00"),
        Stock(stockCode: "051910", stockName: "LG화학", market: "KOSPI", currentPrice: 380_000, priceChangedAt: "2026-05-13T15:30:00"),
        Stock(stockCode: "247540", stockName: "에코프로비엠", market: "KOSDAQ", currentPrice: 142_500, priceChangedAt: "2026-05-13T15:30:00")
    ]
}
