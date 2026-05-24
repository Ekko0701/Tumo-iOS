import TumoNetwork

/// OrderFeature의 실제 의존성 그래프를 조립하는 객체.
enum OrderAssembly {
    static func live() -> OrderClient {
        let provider: Provider<OrderAPI> = TumoProviderFactory.live.authorizedProvider()

        let orderDataSource = OrderDataSourceImpl(provider: provider)
        let orderRepository = OrderRepositoryImpl(orderDataSource: orderDataSource)
        let buyStockUsecase = BuyStockUsecaseImpl(orderRepository: orderRepository)

        return OrderClient.live(buyStockUsecase: buyStockUsecase)
    }
}
