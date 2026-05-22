import ComposableArchitecture

@Reducer
public struct StockFeature {
    @Dependency(\.stockClient) private var stockClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var stocks: [Stock] = []
        public var isLoading = false
        public var errorMessage: String?

        public init(
            stocks: [Stock] = [],
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.stocks = stocks
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }

        var isEmptyStateVisible: Bool {
            !isLoading && errorMessage == nil && stocks.isEmpty
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refreshButtonTapped
        case stocksLoaded([Stock])
        case stocksFailed(String)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.stocks.isEmpty else {
                    return .none
                }

                return loadStocks(&state)

            case .refreshButtonTapped:
                return loadStocks(&state)

            case .stocksLoaded(let stocks):
                state.isLoading = false
                state.stocks = stocks
                state.errorMessage = nil
                return .none

            case .stocksFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }

    private func loadStocks(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil

        let stockClient = stockClient

        return .run { send in
            do {
                let stocks = try await stockClient.fetchStocks()
                await send(.stocksLoaded(stocks))
            } catch {
                await send(.stocksFailed("종목 정보를 불러오지 못했습니다."))
            }
        }
    }
}
