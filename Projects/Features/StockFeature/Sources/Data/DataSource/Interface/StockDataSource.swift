protocol StockDataSource: Sendable {
    func fetchStocks() async throws -> StockListResponseDTO
    func fetchStock(stockCode: String) async throws -> StockResponseDTO
}
