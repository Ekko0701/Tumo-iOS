import ComposableArchitecture

/// TCA Reducer에서 사용할 종목 API 의존성.
public struct StockClient: Sendable {
    public var fetchStocks: @Sendable (
        _ market: StockMarket,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPage

    public var fetchStockRankings: @Sendable (
        _ market: StockMarket,
        _ type: StockRankingType,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPage

    public var fetchStock: @Sendable (_ stockCode: String) async throws -> Stock

    public var observeRealtimePrices: @Sendable (
        _ stockCodes: [String]
    ) -> AsyncThrowingStream<StockRealtimeEvent, Error>

    public var observeOrderBook: @Sendable (
        _ stockCode: String
    ) -> AsyncThrowingStream<StockOrderBookEvent, Error>

    public var fetchHolding: @Sendable (_ stockCode: String) async throws -> StockHolding?

    public var fetchPortfolio: @Sendable () async throws -> Portfolio

    public var fetchCandles: @Sendable (
        _ stockCode: String,
        _ interval: CandleInterval,
        _ from: String,
        _ to: String
    ) async throws -> [StockCandle]

    public var fetchWatchlist: @Sendable (_ page: Int, _ size: Int) async throws -> StockPage

    public var fetchWatched: @Sendable (_ stockCode: String) async throws -> Bool

    public var addToWatchlist: @Sendable (_ stockCode: String) async throws -> Void

    public var removeFromWatchlist: @Sendable (_ stockCode: String) async throws -> Void

    public init(
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
        fetchStock: @escaping @Sendable (_ stockCode: String) async throws -> Stock,
        observeRealtimePrices: @escaping @Sendable (
            _ stockCodes: [String]
        ) -> AsyncThrowingStream<StockRealtimeEvent, Error>,
        observeOrderBook: @escaping @Sendable (
            _ stockCode: String
        ) -> AsyncThrowingStream<StockOrderBookEvent, Error>,
        fetchHolding: @escaping @Sendable (_ stockCode: String) async throws -> StockHolding?,
        fetchPortfolio: @escaping @Sendable () async throws -> Portfolio,
        fetchCandles: @escaping @Sendable (
            _ stockCode: String,
            _ interval: CandleInterval,
            _ from: String,
            _ to: String
        ) async throws -> [StockCandle],
        fetchWatchlist: @escaping @Sendable (_ page: Int, _ size: Int) async throws -> StockPage,
        fetchWatched: @escaping @Sendable (_ stockCode: String) async throws -> Bool,
        addToWatchlist: @escaping @Sendable (_ stockCode: String) async throws -> Void,
        removeFromWatchlist: @escaping @Sendable (_ stockCode: String) async throws -> Void
    ) {
        self.fetchStocks = fetchStocks
        self.fetchStockRankings = fetchStockRankings
        self.fetchStock = fetchStock
        self.observeRealtimePrices = observeRealtimePrices
        self.observeOrderBook = observeOrderBook
        self.fetchHolding = fetchHolding
        self.fetchPortfolio = fetchPortfolio
        self.fetchCandles = fetchCandles
        self.fetchWatchlist = fetchWatchlist
        self.fetchWatched = fetchWatched
        self.addToWatchlist = addToWatchlist
        self.removeFromWatchlist = removeFromWatchlist
    }
}

extension StockClient {
    static func live(
        fetchStocksUsecase: any FetchStocksUsecase,
        fetchStockRankingsUsecase: any FetchStockRankingsUsecase,
        fetchStockUsecase: any FetchStockUsecase,
        observeRealtimePricesUsecase: any ObserveRealtimePricesUsecase,
        observeOrderBookUsecase: any ObserveOrderBookUsecase,
        fetchHoldingUsecase: any FetchHoldingUsecase,
        fetchPortfolioUsecase: any FetchPortfolioUsecase,
        fetchCandlesUsecase: any FetchCandlesUsecase,
        fetchWatchlistUsecase: any FetchWatchlistUsecase,
        fetchWatchedUsecase: any FetchWatchedUsecase,
        addToWatchlistUsecase: any AddToWatchlistUsecase,
        removeFromWatchlistUsecase: any RemoveFromWatchlistUsecase
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
            },
            observeRealtimePrices: { stockCodes in
                observeRealtimePricesUsecase.execute(stockCodes: stockCodes)
            },
            observeOrderBook: { stockCode in
                observeOrderBookUsecase.execute(stockCode: stockCode)
            },
            fetchHolding: { stockCode in
                try await fetchHoldingUsecase.execute(stockCode: stockCode)
            },
            fetchPortfolio: {
                try await fetchPortfolioUsecase.execute()
            },
            fetchCandles: { stockCode, interval, from, to in
                try await fetchCandlesUsecase.execute(
                    stockCode: stockCode,
                    interval: interval,
                    from: from,
                    to: to
                )
            },
            fetchWatchlist: { page, size in
                try await fetchWatchlistUsecase.execute(page: page, size: size)
            },
            fetchWatched: { stockCode in
                try await fetchWatchedUsecase.execute(stockCode: stockCode)
            },
            addToWatchlist: { stockCode in
                try await addToWatchlistUsecase.execute(stockCode: stockCode)
            },
            removeFromWatchlist: { stockCode in
                try await removeFromWatchlistUsecase.execute(stockCode: stockCode)
            }
        )
    }
}

private enum StockClientKey: DependencyKey {
    static let liveValue = StockAssembly.live()

    static let testValue = StockClient(
        fetchStocks: { _, _, _ in fatalError("unimplemented") },
        fetchStockRankings: { _, _, _, _ in fatalError("unimplemented") },
        fetchStock: { _ in fatalError("unimplemented") },
        observeRealtimePrices: { _ in .never },
        observeOrderBook: { _ in .never },
        fetchHolding: { _ in fatalError("unimplemented") },
        fetchPortfolio: { fatalError("unimplemented") },
        fetchCandles: { _, _, _, _ in fatalError("unimplemented") },
        fetchWatchlist: { _, _ in fatalError("unimplemented") },
        fetchWatched: { _ in fatalError("unimplemented") },
        addToWatchlist: { _ in },
        removeFromWatchlist: { _ in }
    )
}

extension DependencyValues {
    public var stockClient: StockClient {
        get { self[StockClientKey.self] }
        set { self[StockClientKey.self] = newValue }
    }
}
