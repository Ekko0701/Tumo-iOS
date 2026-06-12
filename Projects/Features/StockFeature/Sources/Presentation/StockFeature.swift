import ComposableArchitecture
import Foundation

/// 종목 리스트 랭킹 기준. 백엔드 `StockRankingType`으로 변환해 서버 랭킹 API를 호출한다.
public enum StockSortOption: String, CaseIterable, Equatable, Sendable, Identifiable {
    case tradeAmount
    case tradeVolume
    case rising
    case falling

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .tradeAmount:
            "거래대금"
        case .tradeVolume:
            "거래량"
        case .rising:
            "상승률"
        case .falling:
            "하락률"
        }
    }

    var rankingType: StockRankingType {
        switch self {
        case .tradeAmount:
            .tradeAmount
        case .tradeVolume:
            .tradeVolume
        case .rising:
            .rising
        case .falling:
            .falling
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
        public var sortOption: StockSortOption = .tradeAmount
        public var isLoading = false
        public var errorMessage: String?

        public init(
            stocks: [Stock] = [],
            sortOption: StockSortOption = .tradeAmount,
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
            stocks
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refreshButtonTapped
        case sortOptionChanged(StockSortOption)
        case stocksLoaded(StockPage)
        case stocksFailed(String)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.stocks.isEmpty else {
                    return .none
                }

                return loadFirstPage(&state)

            case .refreshButtonTapped:
                return loadFirstPage(&state)

            case .sortOptionChanged(let option):
                guard state.sortOption != option else {
                    return .none
                }

                state.sortOption = option
                state.stocks = []
                return loadFirstPage(&state)

            case .stocksLoaded(let stockPage):
                state.isLoading = false
                state.stocks = stockPage.stocks
                state.errorMessage = nil
                return .none

            case .stocksFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }

    /// 시장 선택 UI를 붙이기 전까지는 KOSPI만 조회한다.
    private static let defaultMarket: StockMarket = .kospi
    private static let rankingPage = 0
    private static let rankingSize = 30

    private func loadFirstPage(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil

        return fetchRankings(rankingType: state.sortOption.rankingType) { .stocksLoaded($0) } onFailure: {
            .stocksFailed("종목 랭킹을 불러오지 못했습니다.")
        }
    }

    private func fetchRankings(
        rankingType: StockRankingType,
        onSuccess: @escaping @Sendable (StockPage) -> Action,
        onFailure: @escaping @Sendable () -> Action
    ) -> Effect<Action> {
        let stockClient = stockClient

        return .run { send in
            do {
                let stockPage = try await stockClient.fetchStockRankings(
                    Self.defaultMarket,
                    rankingType,
                    Self.rankingPage,
                    Self.rankingSize
                )
                await send(onSuccess(stockPage))
            } catch {
                await send(onFailure())
            }
        }
    }
}
