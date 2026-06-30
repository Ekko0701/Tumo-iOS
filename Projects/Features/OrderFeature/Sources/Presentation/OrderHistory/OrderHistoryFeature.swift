import ComposableArchitecture

@Reducer
public struct OrderHistoryFeature {
    @Dependency(\.orderClient) private var orderClient

    public init() {}

    private static let pageSize = 30

    @ObservableState
    public struct State: Equatable {
        public var items: [OrderHistoryItem]
        public var page: Int
        public var hasNext: Bool
        public var isLoading: Bool
        public var errorMessage: String?

        public init(items: [OrderHistoryItem] = [], page: Int = 0, hasNext: Bool = true,
                    isLoading: Bool = false, errorMessage: String? = nil) {
            self.items = items
            self.page = page
            self.hasNext = hasNext
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Equatable {
        case onAppear
        case loadNextPage
        case pageLoaded(OrderPage)
        case loadFailed
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.items.isEmpty, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return loadPage(0)

            case .loadNextPage:
                guard state.hasNext, !state.isLoading else { return .none }
                state.isLoading = true
                return loadPage(state.page + 1)

            case let .pageLoaded(page):
                state.isLoading = false
                state.errorMessage = nil
                if page.page == 0 {
                    state.items = page.items
                } else {
                    state.items += page.items
                }
                state.page = page.page
                state.hasNext = page.hasNext
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "주문 내역을 불러오지 못했습니다."
                return .none
            }
        }
    }

    private func loadPage(_ page: Int) -> Effect<Action> {
        let orderClient = orderClient
        return .run { send in
            do {
                let result = try await orderClient.history(page, Self.pageSize)
                await send(.pageLoaded(result))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
