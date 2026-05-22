protocol FetchStocksUsecase: Sendable {
    func execute() async throws -> [Stock]
}
