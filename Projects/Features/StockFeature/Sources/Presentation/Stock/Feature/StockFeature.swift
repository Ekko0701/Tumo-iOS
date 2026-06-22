import ComposableArchitecture
import CoreNetwork
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
    @Dependency(\.continuousClock) private var clock

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var stocks: [Stock] = []
        public var sortOption: StockSortOption = .tradeAmount
        public var isLoading = false
        public var errorMessage: String?
        /// 실시간 stream 연속 실패 횟수. 재연결 backoff 계산에 사용한다.
        public var realtimeRetryCount = 0
        /// 종목 행을 탭하면 띄우는 상세 화면 상태.
        @Presents public var detail: StockDetailFeature.State?

        public init(
            stocks: [Stock] = [],
            sortOption: StockSortOption = .tradeAmount,
            isLoading: Bool = false,
            errorMessage: String? = nil,
            realtimeRetryCount: Int = 0,
            detail: StockDetailFeature.State? = nil
        ) {
            self.stocks = stocks
            self.sortOption = sortOption
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.realtimeRetryCount = realtimeRetryCount
            self.detail = detail
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
        case onDisappear
        case refreshButtonTapped
        case sortOptionChanged(StockSortOption)
        case stocksLoaded(StockPage)
        case stocksFailed(String)
        /// 현재 리스트의 종목들로 실시간 체결가 stream 구독을 (재)시작한다.
        case startRealtimeUpdates
        /// SSE 연결이 살아있음을 확인했다(첫 이벤트 수신). 재연결 backoff를 리셋한다.
        case realtimeStreamConnected
        case realtimePriceReceived(StockPriceUpdate)
        /// stream이 끊기거나(서버 timeout 포함) 실패했을 때 backoff 후 재연결한다.
        case realtimeStreamFailed
        /// 종목 행을 탭해 상세 화면을 띄운다.
        case stockTapped(Stock)
        /// 상세 화면(@Presents) 액션.
        case detail(PresentationAction<StockDetailFeature.Action>)
    }

    private enum CancelID {
        case realtimePrices
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 이미 목록이 있으면(탭 복귀 등) 재로딩은 건너뛰되, onDisappear에서
                // 해제됐던 실시간 구독은 다시 시작한다.
                guard state.stocks.isEmpty else {
                    return .send(.startRealtimeUpdates)
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
                state.realtimeRetryCount = 0
                // 리스트 구성이 바뀌었으므로 새 종목 코드들로 실시간 구독을 재시작한다.
                return .send(.startRealtimeUpdates)

            case .stocksFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .startRealtimeUpdates:
                let stockCodes = state.stocks.map(\.stockCode)

                guard !stockCodes.isEmpty else {
                    return .cancel(id: CancelID.realtimePrices)
                }

                let stockClient = stockClient

                return .run { send in
                    do {
                        for try await event in stockClient.observeRealtimePrices(stockCodes) {
                            switch event {
                            case .connected:
                                await send(.realtimeStreamConnected)
                            case .priceUpdated(let update):
                                await send(.realtimePriceReceived(update))
                            }
                        }
                        // 서버 SSE timeout 등으로 정상 종료된 경우에도 재연결한다.
                        await send(.realtimeStreamFailed)
                    } catch {
                        await send(.realtimeStreamFailed)
                    }
                }
                .cancellable(id: CancelID.realtimePrices, cancelInFlight: true)

            case .realtimeStreamConnected:
                // 연결이 살아있음을 확인했으므로(첫 이벤트 수신) 재연결 backoff를 리셋한다.
                state.realtimeRetryCount = 0
                return .none

            case .realtimePriceReceived(let update):
                state.stocks = state.stocks.map { stock in
                    guard stock.stockCode == update.stockCode else {
                        return stock
                    }

                    return Stock(
                        stockCode: stock.stockCode,
                        stockName: stock.stockName,
                        market: stock.market,
                        currentPrice: update.currentPrice,
                        changePrice: update.changePrice,
                        changeRate: update.changeRate,
                        tradeVolume: update.tradeVolume,
                        tradeAmount: update.tradeAmount,
                        priceChangedAt: update.priceChangedAt
                    )
                }
                return .none

            case .realtimeStreamFailed:
                state.realtimeRetryCount += 1
                let delay = SseReconnectBackoff.delay(retryCount: state.realtimeRetryCount)
                let clock = clock

                return .run { send in
                    try await clock.sleep(for: .seconds(delay))
                    await send(.startRealtimeUpdates)
                }
                .cancellable(id: CancelID.realtimePrices, cancelInFlight: true)

            case .onDisappear:
                return .cancel(id: CancelID.realtimePrices)

            case .stockTapped(let stock):
                // 리스트의 Stock 전체를 넘겨 헤더를 즉시 표시한다(fetch 대기 없음).
                state.detail = StockDetailFeature.State(stock: stock)
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            StockDetailFeature()
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
