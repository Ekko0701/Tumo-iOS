import TumoNetwork

/// StockFeature의 실제 의존성 그래프를 조립하는 객체.
enum StockAssembly {
    static func live() -> StockClient {
        let provider: Provider<StockAPI> = TumoProviderFactory.live.authorizedProvider()

        let stockDataSource = StockDataSourceImpl(provider: provider)
        let stockRepository = StockRepositoryImpl(stockDataSource: stockDataSource)
        let fetchStocksUsecase = FetchStocksUsecaseImpl(stockRepository: stockRepository)
        let fetchStockRankingsUsecase = FetchStockRankingsUsecaseImpl(stockRepository: stockRepository)
        let fetchStockUsecase = FetchStockUsecaseImpl(stockRepository: stockRepository)

        return StockClient.live(
            fetchStocksUsecase: fetchStocksUsecase,
            fetchStockRankingsUsecase: fetchStockRankingsUsecase,
            fetchStockUsecase: fetchStockUsecase
        )
    }
}
