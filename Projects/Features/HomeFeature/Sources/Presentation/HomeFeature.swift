import ComposableArchitecture
import OrderFeature
import StockFeature

@Reducer
public struct HomeFeature {
    @Dependency(\.stockClient) private var stockClient
    @Dependency(\.orderClient) private var orderClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var portfolio: Portfolio?
        public var topMovers: [Stock]
        public var recentOrders: [OrderHistoryItem]
        public var isLoading: Bool
        public var errorMessage: String?
        @Presents public var stockDetail: StockDetailFeature.State?

        public init(portfolio: Portfolio? = nil, topMovers: [Stock] = [], recentOrders: [OrderHistoryItem] = [],
                    isLoading: Bool = false, errorMessage: String? = nil,
                    stockDetail: StockDetailFeature.State? = nil) {
            self.portfolio = portfolio
            self.topMovers = topMovers
            self.recentOrders = recentOrders
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.stockDetail = stockDetail
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case dataLoaded(Portfolio, [Stock], [OrderHistoryItem])
        case loadFailed
        case stockTapped(Stock)
        case stockDetail(PresentationAction<StockDetailFeature.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.portfolio == nil, !state.isLoading else { return .none }
                return load(&state)

            case .refresh:
                return load(&state)

            case let .dataLoaded(portfolio, movers, orders):
                state.isLoading = false
                state.errorMessage = nil
                state.portfolio = portfolio
                state.topMovers = movers
                state.recentOrders = orders
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "홈 정보를 불러오지 못했습니다."
                return .none

            case let .stockTapped(stock):
                state.stockDetail = StockDetailFeature.State(stock: stock)
                return .none

            case .stockDetail:
                return .none
            }
        }
        .ifLet(\.$stockDetail, action: \.stockDetail) {
            StockDetailFeature()
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let stockClient = stockClient
        let orderClient = orderClient
        return .run { send in
            do {
                async let portfolio = stockClient.fetchPortfolio()
                async let movers = stockClient.fetchStockRankings(.kospi, .rising, 0, 5)
                async let orders = orderClient.history(0, 5)
                let (p, m, o) = try await (portfolio, movers, orders)
                await send(.dataLoaded(p, m.stocks, o.items))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
