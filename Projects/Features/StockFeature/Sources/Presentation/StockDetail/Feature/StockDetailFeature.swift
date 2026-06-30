import ComposableArchitecture
import CoreNetwork
import Foundation
import OrderFeature

@Reducer
public struct StockDetailFeature {
    @Dependency(\.stockClient) private var stockClient
    @Dependency(\.continuousClock) private var clock
    @Dependency(\.date) private var date
    @Dependency(\.calendar) private var calendar

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
        /// 차트 탭 캔들. interval 전환 시 재조회한다. 과거 스크롤 시 앞쪽에 prepend한다.
        public var candles: [StockCandle]
        public var selectedInterval: CandleInterval
        public var isCandleLoading: Bool
        public var candleErrorMessage: String?
        /// 과거 캔들 추가 조회가 진행 중인지(중복 요청 방지).
        public var isLoadingOlderCandles: Bool
        /// 더 받을 과거 캔들이 남아 있는지. 추가 조회가 빈 결과면 false로 내려 무한 요청을 막는다.
        public var hasMoreCandleHistory: Bool
        /// 헤더 가격 stream 연속 실패 횟수(재연결 backoff).
        public var priceRetryCount: Int
        /// 호가 stream 연속 실패 횟수(재연결 backoff).
        public var orderBookRetryCount: Int
        /// 주문 시트 presentation 상태.
        @Presents public var orderSheet: OrderSheetFeature.State?

        public init(
            stock: Stock,
            selectedTab: Tab = .chart,
            orderBook: StockOrderBook? = nil,
            holding: StockHolding? = nil,
            isHoldingLoaded: Bool = false,
            holdingErrorMessage: String? = nil,
            candles: [StockCandle] = [],
            selectedInterval: CandleInterval = .day,
            isCandleLoading: Bool = false,
            candleErrorMessage: String? = nil,
            isLoadingOlderCandles: Bool = false,
            hasMoreCandleHistory: Bool = true,
            priceRetryCount: Int = 0,
            orderBookRetryCount: Int = 0,
            orderSheet: OrderSheetFeature.State? = nil
        ) {
            self.stock = stock
            self.selectedTab = selectedTab
            self.orderBook = orderBook
            self.holding = holding
            self.isHoldingLoaded = isHoldingLoaded
            self.holdingErrorMessage = holdingErrorMessage
            self.candles = candles
            self.selectedInterval = selectedInterval
            self.isCandleLoading = isCandleLoading
            self.candleErrorMessage = candleErrorMessage
            self.isLoadingOlderCandles = isLoadingOlderCandles
            self.hasMoreCandleHistory = hasMoreCandleHistory
            self.priceRetryCount = priceRetryCount
            self.orderBookRetryCount = orderBookRetryCount
            self.orderSheet = orderSheet
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

        // 차트(캔들)
        case intervalSelected(CandleInterval)
        case loadCandles
        case candlesLoaded([StockCandle])
        case candlesFailed
        // 과거 캔들 추가 로딩(차트 왼쪽 끝 스크롤)
        case loadOlderCandles
        case olderCandlesLoaded([StockCandle])
        case olderCandlesFailed

        // 주문 시트
        case buyTapped
        case sellTapped
        case orderSheet(PresentationAction<OrderSheetFeature.Action>)
    }

    private enum CancelID {
        case headerPrice
        case orderBook
        case holding
        case candles
        case olderCandles
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 헤더 현재가는 상세가 떠 있는 동안 항상 구독한다.
                // 하단 바의 매도 버튼 활성화를 위해 보유 정보는 항상 한 번 로드한다.
                return .merge(
                    .send(.startPriceStream),
                    state.isHoldingLoaded ? .none : .send(.loadHolding),
                    effectOnEnter(tab: state.selectedTab, state: state)
                )

            case .onDisappear:
                return .merge(
                    .cancel(id: CancelID.headerPrice),
                    .cancel(id: CancelID.orderBook),
                    .cancel(id: CancelID.holding),
                    .cancel(id: CancelID.candles),
                    .cancel(id: CancelID.olderCandles)
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
                let delay = SseReconnectBackoff.delay(retryCount: state.priceRetryCount)
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
                let delay = SseReconnectBackoff.delay(retryCount: state.orderBookRetryCount)
                let clock = clock

                return .run { send in
                    try await clock.sleep(for: .seconds(delay))
                    await send(.startOrderBookStream)
                }
                .cancellable(id: CancelID.orderBook, cancelInFlight: true)

            case .loadHolding:
                let stockCode = state.stock.stockCode
                let stockClient = stockClient
                state.holdingErrorMessage = nil

                return .run { send in
                    do {
                        let holding = try await stockClient.fetchHolding(stockCode)
                        await send(.holdingLoaded(holding))
                    } catch {
                        await send(.holdingFailed)
                    }
                }
                .cancellable(id: CancelID.holding, cancelInFlight: true)

            case .holdingLoaded(let holding):
                state.holding = holding
                state.isHoldingLoaded = true
                state.holdingErrorMessage = nil
                return .none

            case .holdingFailed:
                // isHoldingLoaded는 false로 둬, 다음 탭 진입 시 재시도한다.
                state.holdingErrorMessage = "보유 정보를 불러오지 못했습니다."
                return .none

            case .intervalSelected(let interval):
                guard state.selectedInterval != interval else {
                    return .none
                }

                state.selectedInterval = interval
                return .send(.loadCandles)

            case .loadCandles:
                let stockCode = state.stock.stockCode
                let interval = state.selectedInterval
                let range = interval.dateRange(asOf: date.now, calendar: calendar)
                let from = Self.dateParamFormatter.string(from: range.from)
                let to = Self.dateParamFormatter.string(from: range.to)
                let stockClient = stockClient

                state.isCandleLoading = true
                state.candleErrorMessage = nil
                // 새 구간을 처음부터 받으므로 과거 추가 로딩 상태를 초기화한다.
                state.isLoadingOlderCandles = false
                state.hasMoreCandleHistory = true

                return .merge(
                    .cancel(id: CancelID.olderCandles),
                    .run { send in
                        do {
                            let candles = try await stockClient.fetchCandles(stockCode, interval, from, to)
                            await send(.candlesLoaded(candles))
                        } catch {
                            await send(.candlesFailed)
                        }
                    }
                    .cancellable(id: CancelID.candles, cancelInFlight: true)
                )

            case .candlesLoaded(let candles):
                state.candles = candles
                state.isCandleLoading = false
                state.candleErrorMessage = nil
                return .none

            case .candlesFailed:
                state.isCandleLoading = false
                state.candleErrorMessage = "차트를 불러오지 못했습니다."
                return .none

            case .loadOlderCandles:
                // 초기 로딩 중이거나, 이미 과거를 받는 중이거나, 더 받을 과거가 없으면 무시한다.
                guard !state.isCandleLoading,
                      !state.isLoadingOlderCandles,
                      state.hasMoreCandleHistory,
                      let earliest = state.candles.first?.candleTime else {
                    return .none
                }

                let stockCode = state.stock.stockCode
                let interval = state.selectedInterval
                let range = interval.previousRange(before: earliest, calendar: calendar)
                let from = Self.dateParamFormatter.string(from: range.from)
                let to = Self.dateParamFormatter.string(from: range.to)
                let stockClient = stockClient

                state.isLoadingOlderCandles = true

                return .run { send in
                    do {
                        let candles = try await stockClient.fetchCandles(stockCode, interval, from, to)
                        await send(.olderCandlesLoaded(candles))
                    } catch {
                        await send(.olderCandlesFailed)
                    }
                }
                .cancellable(id: CancelID.olderCandles, cancelInFlight: true)

            case .olderCandlesLoaded(let older):
                state.isLoadingOlderCandles = false

                let existingTimes = Set(state.candles.map(\.candleTime))
                let fresh = older.filter { !existingTimes.contains($0.candleTime) }

                guard !fresh.isEmpty else {
                    // 새로 받은 과거 봉이 없으면 더 받을 과거가 없다고 보고 추가 요청을 멈춘다.
                    state.hasMoreCandleHistory = false
                    return .none
                }

                state.candles = (fresh + state.candles).sorted { $0.candleTime < $1.candleTime }
                return .none

            case .olderCandlesFailed:
                // 일시 실패: hasMoreCandleHistory는 유지해 다음 스크롤에서 재시도할 수 있게 한다.
                state.isLoadingOlderCandles = false
                return .none

            case .buyTapped:
                state.orderSheet = OrderSheetFeature.State(
                    stockCode: state.stock.stockCode,
                    stockName: state.stock.stockName,
                    currentPrice: state.stock.currentPrice,
                    mode: .buy,
                    ownedQuantity: state.holding?.quantity ?? 0
                )
                return .none

            case .sellTapped:
                state.orderSheet = OrderSheetFeature.State(
                    stockCode: state.stock.stockCode,
                    stockName: state.stock.stockName,
                    currentPrice: state.stock.currentPrice,
                    mode: .sell,
                    ownedQuantity: state.holding?.quantity ?? 0
                )
                return .none

            case .orderSheet(.presented(.delegate(.orderCompleted))):
                state.isHoldingLoaded = false
                return .send(.loadHolding)

            case .orderSheet:
                return .none
            }
        }
        .ifLet(\.$orderSheet, action: \.orderSheet) {
            OrderSheetFeature()
        }
    }

    /// 캔들 API의 `from`/`to` 쿼리(`yyyyMMdd`)를 만드는 KST 포맷터.
    private static let dateParamFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    /// 탭 진입 시 필요한 effect.
    /// 호가 탭이면 호가 구독을 시작하고, 그 외 탭이면 호가 구독을 정리한다.
    /// MY주식 탭은 아직 로드 전이면 보유 정보를 한 번 조회한다.
    private func effectOnEnter(tab: Tab, state: State) -> Effect<Action> {
        switch tab {
        case .chart:
            let load: Effect<Action> = (state.candles.isEmpty && !state.isCandleLoading)
                ? .send(.loadCandles)
                : .none
            return .merge(.cancel(id: CancelID.orderBook), load)

        case .orderBook:
            return .send(.startOrderBookStream)

        case .myStock:
            let load: Effect<Action> = state.isHoldingLoaded ? .none : .send(.loadHolding)
            return .merge(.cancel(id: CancelID.orderBook), load)
        }
    }
}
