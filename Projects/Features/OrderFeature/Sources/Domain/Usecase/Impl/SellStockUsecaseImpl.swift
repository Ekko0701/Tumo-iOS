/// 종목 매도 주문을 실행하는 유스케이스 구현체.
struct SellStockUsecaseImpl: SellStockUsecase {
    private let orderRepository: any OrderRepository

    init(orderRepository: any OrderRepository) {
        self.orderRepository = orderRepository
    }

    func execute(stockCode: String, quantity: Int) async throws -> Order {
        try await orderRepository.sell(stockCode: stockCode, quantity: quantity)
    }
}
