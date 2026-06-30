import ComposableArchitecture

/// TCA Reducer에서 사용할 주문 API 의존성.
struct OrderClient: Sendable {
    var buy: @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order
    var sell: @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order
    var history: @Sendable (_ page: Int, _ size: Int) async throws -> OrderPage

    init(
        buy: @escaping @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order,
        sell: @escaping @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order,
        history: @escaping @Sendable (_ page: Int, _ size: Int) async throws -> OrderPage
    ) {
        self.buy = buy
        self.sell = sell
        self.history = history
    }
}

extension OrderClient {
    static func live(
        buyStockUsecase: any BuyStockUsecase,
        sellStockUsecase: any SellStockUsecase,
        fetchOrderHistoryUsecase: any FetchOrderHistoryUsecase
    ) -> OrderClient {
        OrderClient(
            buy: { try await buyStockUsecase.execute(stockCode: $0, quantity: $1) },
            sell: { try await sellStockUsecase.execute(stockCode: $0, quantity: $1) },
            history: { try await fetchOrderHistoryUsecase.execute(page: $0, size: $1) }
        )
    }
}

private enum OrderClientKey: DependencyKey {
    static let liveValue = OrderAssembly.live()

    static let testValue = OrderClient(
        buy: { _, _ in fatalError("unimplemented") },
        sell: { _, _ in fatalError("unimplemented") },
        history: { _, _ in fatalError("unimplemented") }
    )
}

extension DependencyValues {
    var orderClient: OrderClient {
        get { self[OrderClientKey.self] }
        set { self[OrderClientKey.self] = newValue }
    }
}
