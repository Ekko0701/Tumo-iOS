protocol ObserveOrderBookUsecase: Sendable {
    func execute(stockCode: String) -> AsyncThrowingStream<StockOrderBookEvent, Error>
}
