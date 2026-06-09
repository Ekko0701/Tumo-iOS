import ComposableArchitecture
import Foundation

/// 종목 리스트 정렬 기준. 현재 보유 필드(이름/가격)만 사용한다.
public enum StockSortOption: String, CaseIterable, Equatable, Sendable, Identifiable {
    case popular
    case name
    case price

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .popular:
            "인기"
        case .name:
            "이름순"
        case .price:
            "가격순"
        }
    }
}

@Reducer
public struct StockFeature {
    @Dependency(\.stockClient) private var stockClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var stocks: [Stock] = []
        public var sortOption: StockSortOption = .popular
        public var isLoading = false
        public var errorMessage: String?

        public init(
            stocks: [Stock] = [],
            sortOption: StockSortOption = .popular,
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.stocks = stocks
            self.sortOption = sortOption
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }

        var isEmptyStateVisible: Bool {
            !isLoading && errorMessage == nil && stocks.isEmpty
        }

        /// 정렬 옵션을 적용한, 화면에 표시할 종목 목록.
        var displayedStocks: [Stock] {
            switch sortOption {
            case .popular:
                stocks
            case .name:
                stocks.sorted { $0.stockName.localizedCompare($1.stockName) == .orderedAscending }
            case .price:
                stocks.sorted { $0.currentPrice > $1.currentPrice }
            }
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refreshButtonTapped
        case sortOptionChanged(StockSortOption)
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

            case .sortOptionChanged(let option):
                state.sortOption = option
                return .none

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
