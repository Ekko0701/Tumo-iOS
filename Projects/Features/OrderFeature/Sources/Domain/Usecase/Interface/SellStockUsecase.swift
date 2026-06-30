/// 종목 매도 주문을 실행하는 유스케이스 인터페이스.
protocol SellStockUsecase: Sendable {
    func execute(stockCode: String, quantity: Int) async throws -> Order
}
