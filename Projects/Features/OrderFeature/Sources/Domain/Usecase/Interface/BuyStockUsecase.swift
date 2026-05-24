/// 종목 매수 주문을 실행하는 유스케이스 인터페이스.
protocol BuyStockUsecase: Sendable {
    func execute(stockCode: String, quantity: Int) async throws -> Order
}
