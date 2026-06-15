import ComposableArchitecture
import Foundation

@Reducer
public struct StockDetailFeature {
    @Dependency(\.stockClient) private var stockClient
    @Dependency(\.continuousClock) private var clock

    public init() {}

    /// 종목 상세 화면의 탭.
    public enum Tab: String, CaseIterable, Equatable, Sendable, Identifiable {
        case chart
        case orderBook
        case myStock

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .chart:
                "차트"
            case .orderBook:
                "호가"
            case .myStock:
                "MY주식"
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: String { stock.stockCode }

        /// 리스트에서 전달받은 종목. 헤더를 즉시 표시하고, 실시간 가격으로 갱신한다.
        public var stock: Stock
        public var selectedTab: Tab
        public var orderBook: StockOrderBook?
        public var holding: StockHolding?
        public var isHoldingLoaded: Bool
        public var holdingErrorMessage: String?
        /// 헤더 가격 stream 연속 실패 횟수(재연결 backoff).
        public var priceRetryCount: Int
        /// 호가 stream 연속 실패 횟수(재연결 backoff).
        public var orderBookRetryCount: Int

        public init(
            stock: Stock,
            selectedTab: Tab = .chart,
            orderBook: StockOrderBook? = nil,
            holding: StockHolding? = nil,
            isHoldingLoaded: Bool = false,
            holdingErrorMessage: String? = nil,
            priceRetryCount: Int = 0,
            orderBookRetryCount: Int = 0
        ) {
            self.stock = stock
            self.selectedTab = selectedTab
            self.orderBook = orderBook
            self.holding = holding
            self.isHoldingLoaded = isHoldingLoaded
            self.holdingErrorMessage = holdingErrorMessage
            self.priceRetryCount = priceRetryCount
            self.orderBookRetryCount = orderBookRetryCount
        }
    }

    public enum Action: Equatable {
        case onAppear
        case onDisappear
        case tabSelected(Tab)

        // 헤더 실시간 현재가
        case startPriceStream
        case priceStreamConnected
        case priceReceived(StockPriceUpdate)
        case priceStreamFailed

        // 호가
        case startOrderBookStream
        case orderBookStreamConnected
        case orderBookReceived(StockOrderBook)
        case orderBookStreamFailed

        // MY주식(보유)
        case loadHolding
        case holdingLoaded(StockHolding?)
        case holdingFailed
    }

    private enum CancelID {
        case headerPrice
        case orderBook
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 헤더 현재가는 상세가 떠 있는 동안 항상 구독한다.
                return .merge(
                    .send(.startPriceStream),
                    effectOnEnter(tab: state.selectedTab, state: state)
                )

            case .onDisappear:
                return .merge(
                    .cancel(id: CancelID.headerPrice),
                    .cancel(id: CancelID.orderBook)
                )

            case .tabSelected(let tab):
                guard state.selectedTab != tab else {
                    return .none
                }

                state.selectedTab = tab
                return effectOnEnter(tab: tab, state: state)

            case .startPriceStream:
                let stockCode = state.stock.stockCode
                let stockClient = stockClient

                return .run { send in
                    do {
                        for try await event in stockClient.observeRealtimePrices([stockCode]) {
                            switch event {
                            case .connected:
                                await send(.priceStreamConnected)
                            case .priceUpdated(let update):
                                await send(.priceReceived(update))
                            }
                        }
                        await send(.priceStreamFailed)
                    } catch {
                        await send(.priceStreamFailed)
                    }
                }
                .cancellable(id: CancelID.headerPrice, cancelInFlight: true)

            case .priceStreamConnected:
                state.priceRetryCount = 0
                return .none

            case .priceReceived(let update):
                guard update.stockCode == state.stock.stockCode else {
                    return .none
                }

                state.stock = Stock(
                    stockCode: state.stock.stockCode,
                    stockName: state.stock.stockName,
                    market: state.stock.market,
                    currentPrice: update.currentPrice,
                    changePrice: update.changePrice,
                    changeRate: update.changeRate,
                    tradeVolume: update.tradeVolume,
                    tradeAmount: update.tradeAmount,
                    priceChangedAt: update.priceChangedAt
                )
                return .none

            case .priceStreamFailed:
                state.priceRetryCount += 1
                let delay = StockFeature.realtimeRetryDelay(retryCount: state.priceRetryCount)
                let clock = clock

                return .run { send in
                    try await clock.sleep(for: .seconds(delay))
                    await send(.startPriceStream)
                }
                .cancellable(id: CancelID.headerPrice, cancelInFlight: true)

            case .startOrderBookStream:
                let stockCode = state.stock.stockCode
                let stockClient = stockClient

                return .run { send in
                    do {
                        for try await event in stockClient.observeOrderBook(stockCode) {
                            switch event {
                            case .connected:
                                await send(.orderBookStreamConnected)
                            case .updated(let orderBook):
                                await send(.orderBookReceived(orderBook))
                            }
                        }
                        await send(.orderBookStreamFailed)
                    } catch {
                        await send(.orderBookStreamFailed)
                    }
                }
                .cancellable(id: CancelID.orderBook, cancelInFlight: true)

            case .orderBookStreamConnected:
                state.orderBookRetryCount = 0
                return .none

            case .orderBookReceived(let orderBook):
                state.orderBook = orderBook
                return .none

            case .orderBookStreamFailed:
                // 호가 탭을 벗어났으면 재연결하지 않는다.
                guard state.selectedTab == .orderBook else {
                    return .none
                }

                state.orderBookRetryCount += 1
                let delay = StockFeature.realtimeRetryDelay(retryCount: state.orderBookRetryCount)
                let clock = clock

                return .run { send in
                    try await clock.sleep(for: .seconds(delay))
                    await send(.startOrderBookStream)
                }
                .cancellable(id: CancelID.orderBook, cancelInFlight: true)

            case .loadHolding:
                let stockCode = state.stock.stockCode
                let stockClient = stockClient

                return .run { send in
                    do {
                        let holding = try await stockClient.fetchHolding(stockCode)
                        await send(.holdingLoaded(holding))
                    } catch {
                        await send(.holdingFailed)
                    }
                }

            case .holdingLoaded(let holding):
                state.holding = holding
                state.isHoldingLoaded = true
                state.holdingErrorMessage = nil
                return .none

            case .holdingFailed:
                // isHoldingLoaded는 false로 둬, 다음 탭 진입 시 재시도한다.
                state.holdingErrorMessage = "보유 정보를 불러오지 못했습니다."
                return .none
            }
        }
    }

    /// 탭 진입 시 필요한 effect.
    /// 호가 탭이면 호가 구독을 시작하고, 그 외 탭이면 호가 구독을 정리한다.
    /// MY주식 탭은 아직 로드 전이면 보유 정보를 한 번 조회한다.
    private func effectOnEnter(tab: Tab, state: State) -> Effect<Action> {
        switch tab {
        case .chart:
            return .cancel(id: CancelID.orderBook)

        case .orderBook:
            return .send(.startOrderBookStream)

        case .myStock:
            let load: Effect<Action> = state.isHoldingLoaded ? .none : .send(.loadHolding)
            return .merge(.cancel(id: CancelID.orderBook), load)
        }
    }
}
