import TumoNetwork

/// 실제 백엔드 종목 API를 호출하는 DataSource 구현체.
struct StockDataSourceImpl: StockDataSource {
    private let provider: Provider<StockAPI>

    init(provider: Provider<StockAPI>) {
        self.provider = provider
    }

    func fetchStocks() async throws -> StockListResponseDTO {
        try await provider.request(
            .stocks,
            as: StockListResponseDTO.self
        )
    }

    func fetchStock(stockCode: String) async throws -> StockResponseDTO {
        try await provider.request(
            .stock(stockCode: stockCode),
            as: StockResponseDTO.self
        )
    }
}
