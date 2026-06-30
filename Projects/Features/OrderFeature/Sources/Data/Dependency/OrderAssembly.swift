import TumoNetwork

/// OrderFeature의 실제 의존성 그래프를 조립하는 객체.
enum OrderAssembly {
    static func live() -> OrderClient {
        let provider: Provider<OrderAPI> = TumoProviderFactory.live.authorizedProvider()

        let orderDataSource = OrderDataSourceImpl(provider: provider)
        let orderRepository = OrderRepositoryImpl(orderDataSource: orderDataSource)
        return OrderClient.live(
            buyStockUsecase: BuyStockUsecaseImpl(orderRepository: orderRepository),
            sellStockUsecase: SellStockUsecaseImpl(orderRepository: orderRepository),
            fetchOrderHistoryUsecase: FetchOrderHistoryUsecaseImpl(orderRepository: orderRepository)
        )
    }
}
