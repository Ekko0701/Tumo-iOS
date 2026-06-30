/// 주문 이력을 조회하는 유스케이스 구현체.
struct FetchOrderHistoryUsecaseImpl: FetchOrderHistoryUsecase {
    private let orderRepository: any OrderRepository

    init(orderRepository: any OrderRepository) {
        self.orderRepository = orderRepository
    }

    func execute(page: Int, size: Int) async throws -> OrderPage {
        try await orderRepository.history(page: page, size: size)
    }
}
