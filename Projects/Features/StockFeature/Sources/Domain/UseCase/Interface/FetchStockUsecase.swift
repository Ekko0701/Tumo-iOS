protocol FetchStockUsecase: Sendable {
    func execute(stockCode: String) async throws -> Stock
}
