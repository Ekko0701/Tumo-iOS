protocol AddToWatchlistUsecase: Sendable {
    func execute(stockCode: String) async throws
}
