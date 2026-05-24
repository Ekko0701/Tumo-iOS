/// 종목 매수 주문을 실행하는 유스케이스 구현체.
struct BuyStockUsecaseImpl: BuyStockUsecase {
    private let orderRepository: any OrderRepository

    init(orderRepository: any OrderRepository) {
        self.orderRepository = orderRepository
    }

    func execute(stockCode: String, quantity: Int) async throws -> Order {
        try await orderRepository.buy(stockCode: stockCode, quantity: quantity)
    }
}
