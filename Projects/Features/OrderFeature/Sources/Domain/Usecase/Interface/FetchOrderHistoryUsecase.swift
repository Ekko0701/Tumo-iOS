/// 주문 이력을 조회하는 유스케이스 인터페이스.
protocol FetchOrderHistoryUsecase: Sendable {
    func execute(page: Int, size: Int) async throws -> OrderPage
}
