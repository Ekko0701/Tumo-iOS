import ComposableArchitecture

/// TCA Reducer에서 사용할 주문 API 의존성.
struct OrderClient: Sendable {
    var buy: @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order

    init(buy: @escaping @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order) {
        self.buy = buy
    }
}

extension OrderClient {
    static func live(
        buyStockUsecase: any BuyStockUsecase
    ) -> OrderClient {
        OrderClient(
            buy: { stockCode, quantity in
                try await buyStockUsecase.execute(stockCode: stockCode, quantity: quantity)
            }
        )
    }
}

private enum OrderClientKey: DependencyKey {
    static let liveValue = OrderAssembly.live()
}

extension DependencyValues {
    var orderClient: OrderClient {
        get { self[OrderClientKey.self] }
        set { self[OrderClientKey.self] = newValue }
    }
}
