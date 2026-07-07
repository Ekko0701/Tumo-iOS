protocol RemoveFromWatchlistUsecase: Sendable {
    func execute(stockCode: String) async throws
}
