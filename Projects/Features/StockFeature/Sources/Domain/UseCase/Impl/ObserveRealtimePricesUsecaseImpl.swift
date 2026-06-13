/// 지정 종목의 실시간 체결가 stream을 구독하는 유스케이스 구현체.
struct ObserveRealtimePricesUsecaseImpl: ObserveRealtimePricesUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEvent, Error> {
        stockRepository.observeRealtimePrices(stockCodes: stockCodes)
    }
}
