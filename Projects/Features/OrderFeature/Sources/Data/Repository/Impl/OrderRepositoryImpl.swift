/// 주문 DataSource 응답 DTO를 Domain Entity로 변환하는 Repository 구현체.
struct OrderRepositoryImpl: OrderRepository {
    private let orderDataSource: any OrderDataSource

    init(orderDataSource: any OrderDataSource) {
        self.orderDataSource = orderDataSource
    }

    func buy(stockCode: String, quantity: Int) async throws -> Order {
        let dto = try await orderDataSource.buy(stockCode: stockCode, quantity: quantity)
        return dto.toEntity()
    }
}

private extension OrderResponseDTO {
    func toEntity() -> Order {
        Order(
            orderId: orderId,
            stockCode: stockCode,
            stockName: stockName,
            orderType: orderType,
            quantity: quantity,
            executedPrice: executedPrice,
            totalAmount: totalAmount,
            cashBalance: cashBalance,
            executedAt: executedAt
        )
    }
}
