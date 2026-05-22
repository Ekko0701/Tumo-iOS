import ComposableArchitecture

/// TCA Reducer에서 사용할 종목 API 의존성.
struct StockClient: Sendable {
    var fetchStocks: @Sendable () async throws -> [Stock]
    var fetchStock: @Sendable (_ stockCode: String) async throws -> Stock

    init(
        fetchStocks: @escaping @Sendable () async throws -> [Stock],
        fetchStock: @escaping @Sendable (_ stockCode: String) async throws -> Stock
    ) {
        self.fetchStocks = fetchStocks
        self.fetchStock = fetchStock
    }
}

extension StockClient {
    static func live(
        fetchStocksUsecase: any FetchStocksUsecase,
        fetchStockUsecase: any FetchStockUsecase
    ) -> StockClient {
        StockClient(
            fetchStocks: {
                try await fetchStocksUsecase.execute()
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
