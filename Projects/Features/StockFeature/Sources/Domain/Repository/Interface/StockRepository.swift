protocol StockRepository: Sendable {
    func fetchStocks() async throws -> [Stock]
    func fetchStock(stockCode: String) async throws -> Stock
}
