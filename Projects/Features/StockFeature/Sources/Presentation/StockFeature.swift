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
        /// 마지막으로 로드한 page 번호.
        public var currentPage = 0
        /// 서버가 알려준 다음 page 존재 여부.
        public var hasNextPage = false
        /// 다음 page 로딩 중 여부. 첫 page 로딩(isLoading)과 구분한다.
        public var isLoadingNextPage = false

        public init(
            stocks: [Stock] = [],
            sortOption: StockSortOption = .popular,
            isLoading: Bool = false,
            errorMessage: String? = nil,
            currentPage: Int = 0,
            hasNextPage: Bool = false,
            isLoadingNextPage: Bool = false
        ) {
            self.stocks = stocks
            self.sortOption = sortOption
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.currentPage = currentPage
            self.hasNextPage = hasNextPage
            self.isLoadingNextPage = isLoadingNextPage
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
        /// 리스트 행이 화면에 나타났을 때 발생. 마지막 행이면 다음 page를 로드한다.
        case rowAppeared(stockCode: String)
        case stocksLoaded(StockPage)
        case nextPageLoaded(StockPage)
        case stocksFailed(String)
        case nextPageFailed
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
                state.sortOption = option
                return .none

            case .rowAppeared(let stockCode):
                guard state.hasNextPage,
                      !state.isLoading,
                      !state.isLoadingNextPage,
                      stockCode == state.displayedStocks.last?.stockCode
                else {
                    return .none
                }

                return loadNextPage(&state)

            case .stocksLoaded(let stockPage):
                state.isLoading = false
                state.stocks = stockPage.stocks
                state.currentPage = stockPage.page
                state.hasNextPage = stockPage.hasNext
                state.errorMessage = nil
                return .none

            case .nextPageLoaded(let stockPage):
                state.isLoadingNextPage = false
                state.currentPage = stockPage.page
                state.hasNextPage = stockPage.hasNext
                state.stocks = appendingWithoutDuplicates(state.stocks, stockPage.stocks)
                return .none

            case .stocksFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .nextPageFailed:
                // 다음 page 실패는 화면을 막지 않는다. 마지막 행이 다시 나타나면 재시도된다.
                state.isLoadingNextPage = false
                return .none
            }
        }
    }

    /// Phase 3(시장 선택·랭킹 UI 연동) 전까지는 KOSPI만 조회한다.
    private static let defaultMarket: StockMarket = .kospi
    private static let firstPage = 0
    private static let defaultPageSize = 30

    private func loadFirstPage(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil

        return fetchPage(Self.firstPage) { .stocksLoaded($0) } onFailure: {
            .stocksFailed("종목 정보를 불러오지 못했습니다.")
        }
    }

    private func loadNextPage(_ state: inout State) -> Effect<Action> {
        state.isLoadingNextPage = true

        return fetchPage(state.currentPage + 1) { .nextPageLoaded($0) } onFailure: {
            .nextPageFailed
        }
    }

    private func fetchPage(
        _ page: Int,
        onSuccess: @escaping @Sendable (StockPage) -> Action,
        onFailure: @escaping @Sendable () -> Action
    ) -> Effect<Action> {
        let stockClient = stockClient

        return .run { send in
            do {
                let stockPage = try await stockClient.fetchStocks(
                    Self.defaultMarket,
                    page,
                    Self.defaultPageSize
                )
                await send(onSuccess(stockPage))
            } catch {
                await send(onFailure())
            }
        }
    }

    /// 새 page와 기존 목록이 겹치더라도(서버 데이터 변동 등) 중복 행이 생기지 않도록 합친다.
    private func appendingWithoutDuplicates(_ stocks: [Stock], _ newStocks: [Stock]) -> [Stock] {
        let existingCodes = Set(stocks.map(\.stockCode))
        return stocks + newStocks.filter { !existingCodes.contains($0.stockCode) }
    }
}
