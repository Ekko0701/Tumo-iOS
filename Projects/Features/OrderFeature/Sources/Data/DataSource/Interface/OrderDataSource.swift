/// 주문 API 호출을 추상화하는 DataSource 인터페이스.
protocol OrderDataSource: Sendable {
    func buy(stockCode: String, quantity: Int) async throws -> OrderResponseDTO
    func sell(stockCode: String, quantity: Int) async throws -> OrderResponseDTO
    func orderHistory(page: Int, size: Int) async throws -> OrderPageDTO
}
