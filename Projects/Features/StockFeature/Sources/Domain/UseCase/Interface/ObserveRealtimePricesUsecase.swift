protocol ObserveRealtimePricesUsecase: Sendable {
    func execute(stockCodes: [String]) -> AsyncThrowingStream<StockPriceUpdate, Error>
}
