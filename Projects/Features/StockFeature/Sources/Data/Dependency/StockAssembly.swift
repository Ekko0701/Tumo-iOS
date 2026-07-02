import TumoNetwork

/// StockFeature의 실제 의존성 그래프를 조립하는 객체.
enum StockAssembly {
    static func live() -> StockClient {
        let provider: Provider<StockAPI> = TumoProviderFactory.live.authorizedProvider()
        let portfolioProvider: Provider<PortfolioAPI> = TumoProviderFactory.live.authorizedProvider()
        let sseClient = TumoProviderFactory.live.authorizedSseClient()

        let stockDataSource = StockDataSourceImpl(
            provider: provider,
            portfolioProvider: portfolioProvider,
            sseClient: sseClient
        )
        let stockRepository = StockRepositoryImpl(stockDataSource: stockDataSource)
        let fetchStocksUsecase = FetchStocksUsecaseImpl(stockRepository: stockRepository)
        let fetchStockRankingsUsecase = FetchStockRankingsUsecaseImpl(stockRepository: stockRepository)
        let fetchStockUsecase = FetchStockUsecaseImpl(stockRepository: stockRepository)
        let observeRealtimePricesUsecase = ObserveRealtimePricesUsecaseImpl(stockRepository: stockRepository)
        let observeOrderBookUsecase = ObserveOrderBookUsecaseImpl(stockRepository: stockRepository)
        let fetchHoldingUsecase = FetchHoldingUsecaseImpl(stockRepository: stockRepository)
        let fetchPortfolioUsecase = FetchPortfolioUsecaseImpl(stockRepository: stockRepository)
        let fetchCandlesUsecase = FetchCandlesUsecaseImpl(stockRepository: stockRepository)

        return StockClient.live(
            fetchStocksUsecase: fetchStocksUsecase,
            fetchStockRankingsUsecase: fetchStockRankingsUsecase,
            fetchStockUsecase: fetchStockUsecase,
            observeRealtimePricesUsecase: observeRealtimePricesUsecase,
            observeOrderBookUsecase: observeOrderBookUsecase,
            fetchHoldingUsecase: fetchHoldingUsecase,
            fetchPortfolioUsecase: fetchPortfolioUsecase,
            fetchCandlesUsecase: fetchCandlesUsecase
        )
    }
}
