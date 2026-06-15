/// 지정 종목의 실시간 호가 stream을 구독하는 유스케이스 구현체.
struct ObserveOrderBookUsecaseImpl: ObserveOrderBookUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCode: String) -> AsyncThrowingStream<StockOrderBookEvent, Error> {
        stockRepository.observeOrderBook(stockCode: stockCode)
    }
}
