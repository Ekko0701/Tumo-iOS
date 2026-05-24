import TumoNetwork

/// 실제 백엔드 주문 API를 호출하는 DataSource 구현체.
struct OrderDataSourceImpl: OrderDataSource {
    private let provider: Provider<OrderAPI>

    init(provider: Provider<OrderAPI>) {
        self.provider = provider
    }

    func buy(stockCode: String, quantity: Int) async throws -> OrderResponseDTO {
        try await provider.request(
            .buy(stockCode: stockCode, quantity: quantity),
            as: OrderResponseDTO.self
        )
    }
}
