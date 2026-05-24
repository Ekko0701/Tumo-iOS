/// 주문 데이터 접근을 추상화하는 Repository 인터페이스.
protocol OrderRepository: Sendable {
    func buy(stockCode: String, quantity: Int) async throws -> Order
}
