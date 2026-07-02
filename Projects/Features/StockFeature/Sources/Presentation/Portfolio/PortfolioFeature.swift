import ComposableArchitecture

@Reducer
public struct PortfolioFeature {
    @Dependency(\.stockClient) private var stockClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var portfolio: Portfolio?
        public var isLoading: Bool
        public var errorMessage: String?
        @Presents public var detail: StockDetailFeature.State?

        public init(portfolio: Portfolio? = nil, isLoading: Bool = false,
                    errorMessage: String? = nil, detail: StockDetailFeature.State? = nil) {
            self.portfolio = portfolio
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.detail = detail
        }

        var isEmptyStateVisible: Bool {
            !isLoading && errorMessage == nil && (portfolio?.holdings.isEmpty ?? false)
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case portfolioLoaded(Portfolio)
        case loadFailed
        case holdingTapped(String)
        case stockLoaded(Stock)
        case stockLoadFailed
        case detail(PresentationAction<StockDetailFeature.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.portfolio == nil, !state.isLoading else { return .none }
                return load(&state)

            case .refresh:
                return load(&state)

            case let .portfolioLoaded(portfolio):
                state.isLoading = false
                state.errorMessage = nil
                state.portfolio = portfolio
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "포트폴리오를 불러오지 못했습니다."
                return .none

            case let .holdingTapped(stockCode):
                let stockClient = stockClient
                return .run { send in
                    do {
                        let stock = try await stockClient.fetchStock(stockCode)
                        await send(.stockLoaded(stock))
                    } catch {
                        await send(.stockLoadFailed)
                    }
                }

            case let .stockLoaded(stock):
                state.detail = StockDetailFeature.State(stock: stock)
                return .none

            case .stockLoadFailed:
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            StockDetailFeature()
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let stockClient = stockClient
        return .run { send in
            do {
                let portfolio = try await stockClient.fetchPortfolio()
                await send(.portfolioLoaded(portfolio))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
