struct FetchPortfolioUsecaseImpl: FetchPortfolioUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute() async throws -> Portfolio {
        try await stockRepository.fetchPortfolio()
    }
}
