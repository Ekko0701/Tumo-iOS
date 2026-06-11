import ComposableArchitecture

/// TCA Reducer에서 사용할 종목 API 의존성.
struct StockClient: Sendable {
    var fetchStocks: @Sendable (
        _ market: StockMarket,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPage

    var fetchStockRankings: @Sendable (
        _ market: StockMarket,
        _ type: StockRankingType,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPage

    var fetchStock: @Sendable (_ stockCode: String) async throws -> Stock

    init(
        fetchStocks: @escaping @Sendable (
            _ market: StockMarket,
            _ page: Int,
            _ size: Int
        ) async throws -> StockPage,
        fetchStockRankings: @escaping @Sendable (
            _ market: StockMarket,
            _ type: StockRankingType,
            _ page: Int,
            _ size: Int
        ) async throws -> StockPage,
        fetchStock: @escaping @Sendable (_ stockCode: String) async throws -> Stock
    ) {
        self.fetchStocks = fetchStocks
        self.fetchStockRankings = fetchStockRankings
        self.fetchStock = fetchStock
    }
}

extension StockClient {
    static func live(
        fetchStocksUsecase: any FetchStocksUsecase,
        fetchStockRankingsUsecase: any FetchStockRankingsUsecase,
        fetchStockUsecase: any FetchStockUsecase
    ) -> StockClient {
        StockClient(
            fetchStocks: { market, page, size in
                try await fetchStocksUsecase.execute(market: market, page: page, size: size)
            },
            fetchStockRankings: { market, type, page, size in
                try await fetchStockRankingsUsecase.execute(
                    market: market,
                    type: type,
                    page: page,
                    size: size
                )
            },
            fetchStock: { stockCode in
                try await fetchStockUsecase.execute(stockCode: stockCode)
            }
        )
    }
}

private enum StockClientKey: DependencyKey {
    static let liveValue = StockAssembly.live()
}

extension DependencyValues {
    var stockClient: StockClient {
        get { self[StockClientKey.self] }
        set { self[StockClientKey.self] = newValue }
    }
}
