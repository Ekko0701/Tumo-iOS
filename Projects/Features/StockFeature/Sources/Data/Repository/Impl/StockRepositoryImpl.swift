/// 종목 DataSource 응답 DTO를 Domain Entity로 변환하는 Repository 구현체.
struct StockRepositoryImpl: StockRepository {
    private let stockDataSource: any StockDataSource

    init(stockDataSource: any StockDataSource) {
        self.stockDataSource = stockDataSource
    }

    func fetchStocks() async throws -> [Stock] {
        let responseDTO = try await stockDataSource.fetchStocks()

        return responseDTO.stocks.map { $0.toEntity() }
    }

    func fetchStock(stockCode: String) async throws -> Stock {
        let responseDTO = try await stockDataSource.fetchStock(stockCode: stockCode)

        return responseDTO.toEntity()
    }
}

private extension StockResponseDTO {
    func toEntity() -> Stock {
        Stock(
            stockCode: stockCode,
            stockName: stockName,
            market: market,
            currentPrice: currentPrice,
            priceChangedAt: priceChangedAt
        )
    }
}
