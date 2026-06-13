protocol ObserveRealtimePricesUsecase: Sendable {
    func execute(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEvent, Error>
}
