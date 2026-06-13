import XCTest
import ComposableArchitecture
@testable import StockFeature

@MainActor
final class StockFeatureTests: XCTestCase {
    func testNamespace() {
        XCTAssertNotNil(StockFeatureNamespace.self)
    }

    func testStockRepositoryMapsPageResponseDTOToEntity() async throws {
        let repository = StockRepositoryImpl(
            stockDataSource: StubStockDataSource(
                fetchStocksHandler: { market, page, size in
                    XCTAssertEqual(market, .kospi)
                    XCTAssertEqual(page, 0)
                    XCTAssertEqual(size, 30)

                    return StockPageResponseDTO(
                        stocks: [
                            StockResponseDTO(
                                stockCode: "005930",
                                stockName: "삼성전자",
                                market: "KOSPI",
                                currentPrice: 75_000,
                                changePrice: 100,
                                changeRate: Decimal(string: "0.13"),
                                tradeVolume: 1_234_567,
                                tradeAmount: 92_592_592_500,
                                priceChangedAt: "2026-05-13T15:30:00"
                            )
                        ],
                        page: 0,
                        size: 30,
                        hasNext: true
                    )
                }
            )
        )

        let stockPage = try await repository.fetchStocks(market: .kospi, page: 0, size: 30)

        XCTAssertEqual(
            stockPage,
            StockPage(
                stocks: [
                    Stock(
                        stockCode: "005930",
                        stockName: "삼성전자",
                        market: "KOSPI",
                        currentPrice: 75_000,
                        changePrice: 100,
                        changeRate: Decimal(string: "0.13"),
                        tradeVolume: 1_234_567,
                        tradeAmount: 92_592_592_500,
                        priceChangedAt: "2026-05-13T15:30:00"
                    )
                ],
                page: 0,
                hasNext: true
            )
        )
    }

    func testStockRepositoryMapsRankingPageResponseDTOToEntity() async throws {
        let repository = StockRepositoryImpl(
            stockDataSource: StubStockDataSource(
                fetchStockRankingsHandler: { market, type, page, size in
                    XCTAssertEqual(market, .kosdaq)
                    XCTAssertEqual(type, .tradeAmount)
                    XCTAssertEqual(page, 1)
                    XCTAssertEqual(size, 30)

                    return StockPageResponseDTO(
                        stocks: [],
                        page: 1,
                        size: 30,
                        hasNext: false
                    )
                }
            )
        )

        let stockPage = try await repository.fetchStockRankings(
            market: .kosdaq,
            type: .tradeAmount,
            page: 1,
            size: 30
        )

        XCTAssertEqual(stockPage, StockPage(stocks: [], page: 1, hasNext: false))
    }

    func testStockRepositoryMapsDetailResponseDTOToEntity() async throws {
        let repository = StockRepositoryImpl(
            stockDataSource: StubStockDataSource(
                fetchStockHandler: { stockCode in
                    XCTAssertEqual(stockCode, "000660")

                    return StockResponseDTO(
                        stockCode: "000660",
                        stockName: "SK하이닉스",
                        market: "KOSPI",
                        currentPrice: 180_000,
                        changePrice: nil,
                        changeRate: nil,
                        tradeVolume: nil,
                        tradeAmount: nil,
                        priceChangedAt: "2026-05-13T15:30:00"
                    )
                }
            )
        )

        let stock = try await repository.fetchStock(stockCode: "000660")

        XCTAssertEqual(
            stock,
            Stock(
                stockCode: "000660",
                stockName: "SK하이닉스",
                market: "KOSPI",
                currentPrice: 180_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        )
    }

    func testFetchStocksUsecasePassesArgumentsToRepository() async throws {
        let expectedPage = StockPage(
            stocks: [
                Stock(
                    stockCode: "035420",
                    stockName: "NAVER",
                    market: "KOSPI",
                    currentPrice: 190_000,
                    priceChangedAt: "2026-05-13T15:30:00"
                )
            ],
            page: 0,
            hasNext: false
        )
        let usecase = FetchStocksUsecaseImpl(
            stockRepository: StubStockRepository(
                fetchStocksHandler: { market, page, size in
                    XCTAssertEqual(market, .kospi)
                    XCTAssertEqual(page, 0)
                    XCTAssertEqual(size, 30)

                    return expectedPage
                }
            )
        )

        let stockPage = try await usecase.execute(market: .kospi, page: 0, size: 30)

        XCTAssertEqual(stockPage, expectedPage)
    }

    func testFetchStockRankingsUsecasePassesArgumentsToRepository() async throws {
        let expectedPage = StockPage(stocks: [], page: 2, hasNext: true)
        let usecase = FetchStockRankingsUsecaseImpl(
            stockRepository: StubStockRepository(
                fetchStockRankingsHandler: { market, type, page, size in
                    XCTAssertEqual(market, .kosdaq)
                    XCTAssertEqual(type, .rising)
                    XCTAssertEqual(page, 2)
                    XCTAssertEqual(size, 10)

                    return expectedPage
                }
            )
        )

        let stockPage = try await usecase.execute(
            market: .kosdaq,
            type: .rising,
            page: 2,
            size: 10
        )

        XCTAssertEqual(stockPage, expectedPage)
    }

    func testFetchStockUsecasePassesStockCodeToRepository() async throws {
        let usecase = FetchStockUsecaseImpl(
            stockRepository: StubStockRepository(
                fetchStockHandler: { stockCode in
                    XCTAssertEqual(stockCode, "035720")

                    return Stock(
                        stockCode: stockCode,
                        stockName: "카카오",
                        market: "KOSPI",
                        currentPrice: 55_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    )
                }
            )
        )

        let stock = try await usecase.execute(stockCode: "035720")

        XCTAssertEqual(stock.stockCode, "035720")
        XCTAssertEqual(stock.stockName, "카카오")
    }

    func testStockFeatureLoadsStocksOnAppear() async {
        let stocks = [
            Stock(
                stockCode: "005930",
                stockName: "삼성전자",
                market: "KOSPI",
                currentPrice: 75_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        ]
        let stockPage = StockPage(stocks: stocks, page: 0, hasNext: false)
        let store = TestStore(initialState: StockFeature.State()) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStockRankings = { market, type, page, size in
                XCTAssertEqual(market, .kospi)
                XCTAssertEqual(type, .tradeAmount)
                XCTAssertEqual(page, 0)
                XCTAssertEqual(size, 30)

                return stockPage
            }
            $0.stockClient.observeRealtimePrices = { _ in .never }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.stocksLoaded(stockPage)) {
            $0.isLoading = false
            $0.stocks = stocks
        }
        await store.receive(.startRealtimeUpdates)
        await store.send(.onDisappear)
    }

    func testStockFeatureOnAppearResumesRealtimeUpdatesWhenStocksAlreadyLoaded() async {
        // 탭 복귀 시나리오: 이미 종목이 있으면 랭킹 API를 재호출하지 않고
        // onDisappear에서 해제됐던 실시간 구독만 다시 시작해야 한다.
        let stocks = [
            Stock(
                stockCode: "005930",
                stockName: "삼성전자",
                market: "KOSPI",
                currentPrice: 75_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        ]
        let store = TestStore(
            initialState: StockFeature.State(stocks: stocks)
        ) {
            StockFeature()
        } withDependencies: {
            // 랭킹 API가 호출되면 테스트 실패시킨다(재로딩이 일어나면 안 됨).
            $0.stockClient.fetchStockRankings = { _, _, _, _ in
                XCTFail("종목이 이미 있을 때는 랭킹 API를 재호출하면 안 된다.")
                return StockPage(stocks: [], page: 0, hasNext: false)
            }
            $0.stockClient.observeRealtimePrices = { _ in .never }
        }

        await store.send(.onAppear)
        await store.receive(.startRealtimeUpdates)
        await store.send(.onDisappear)
    }

    func testStockFeatureSortOptionChangedLoadsRankingPage() async {
        let ma = Stock(
            stockCode: "000002",
            stockName: "마루소프트",
            market: "KOSDAQ",
            currentPrice: 150_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
        let ba = Stock(
            stockCode: "000003",
            stockName: "바다물산",
            market: "KOSPI",
            currentPrice: 100_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
        let risingPage = StockPage(stocks: [ma, ba], page: 0, hasNext: true)
        let store = TestStore(
            initialState: StockFeature.State()
        ) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStockRankings = { market, type, page, size in
                XCTAssertEqual(market, .kospi)
                XCTAssertEqual(type, .rising)
                XCTAssertEqual(page, 0)
                XCTAssertEqual(size, 30)

                return risingPage
            }
            $0.stockClient.observeRealtimePrices = { _ in .never }
        }

        await store.send(.sortOptionChanged(.rising)) {
            $0.sortOption = .rising
            $0.isLoading = true
        }
        await store.receive(.stocksLoaded(risingPage)) {
            $0.isLoading = false
            $0.stocks = [ma, ba]
        }
        await store.receive(.startRealtimeUpdates)
        await store.send(.onDisappear)
    }

    func testStockFeatureRealtimePriceUpdatesOnlyMatchingStock() async {
        let samsung = Stock(
            stockCode: "005930",
            stockName: "삼성전자",
            market: "KOSPI",
            currentPrice: 75_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
        let skHynix = Stock(
            stockCode: "000660",
            stockName: "SK하이닉스",
            market: "KOSPI",
            currentPrice: 180_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
        let store = TestStore(
            initialState: StockFeature.State(stocks: [samsung, skHynix])
        ) {
            StockFeature()
        }
        let update = StockPriceUpdate(
            stockCode: "005930",
            currentPrice: 76_000,
            changePrice: 1_000,
            changeRate: Decimal(string: "1.33"),
            tradeVolume: 2_000_000,
            tradeAmount: 152_000_000_000,
            priceChangedAt: "2026-05-13T15:31:00"
        )

        await store.send(.realtimePriceReceived(update)) {
            $0.stocks = [
                Stock(
                    stockCode: "005930",
                    stockName: "삼성전자",
                    market: "KOSPI",
                    currentPrice: 76_000,
                    changePrice: 1_000,
                    changeRate: Decimal(string: "1.33"),
                    tradeVolume: 2_000_000,
                    tradeAmount: 152_000_000_000,
                    priceChangedAt: "2026-05-13T15:31:00"
                ),
                skHynix
            ]
        }

        // 리스트에 없는 종목 코드는 무시한다.
        let unknownUpdate = StockPriceUpdate(
            stockCode: "999999",
            currentPrice: 1,
            priceChangedAt: "2026-05-13T15:31:00"
        )
        await store.send(.realtimePriceReceived(unknownUpdate))
    }

    func testStockFeatureStartRealtimeUpdatesYieldsReceivedPrices() async {
        let samsung = Stock(
            stockCode: "005930",
            stockName: "삼성전자",
            market: "KOSPI",
            currentPrice: 75_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
        let update = StockPriceUpdate(
            stockCode: "005930",
            currentPrice: 76_000,
            priceChangedAt: "2026-05-13T15:31:00"
        )
        let store = TestStore(
            initialState: StockFeature.State(stocks: [samsung])
        ) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.observeRealtimePrices = { stockCodes in
                XCTAssertEqual(stockCodes, ["005930"])

                return AsyncThrowingStream { continuation in
                    continuation.yield(.connected)
                    continuation.yield(.priceUpdated(update))
                    // finish하지 않고 유지해 재연결 분기와 분리한다.
                }
            }
        }

        await store.send(.startRealtimeUpdates)
        // 첫 이벤트로 연결을 확인한다(retryCount는 이미 0이라 상태 변화 없음).
        await store.receive(.realtimeStreamConnected)
        await store.receive(.realtimePriceReceived(update)) {
            $0.stocks = [
                Stock(
                    stockCode: "005930",
                    stockName: "삼성전자",
                    market: "KOSPI",
                    currentPrice: 76_000,
                    priceChangedAt: "2026-05-13T15:31:00"
                )
            ]
        }
        await store.send(.onDisappear)
    }

    func testStockFeatureRealtimeStreamConnectedResetsRetryCount() async {
        // 연결이 살아있다는 신호(첫 이벤트 수신)를 받으면, 가격 데이터가 아직
        // 안 왔더라도(장 마감 등) backoff 카운터를 리셋해야 한다.
        let store = TestStore(
            initialState: StockFeature.State(realtimeRetryCount: 3)
        ) {
            StockFeature()
        }

        await store.send(.realtimeStreamConnected) {
            $0.realtimeRetryCount = 0
        }
    }

    func testStockFeatureReconnectsAfterStreamEndsWithBackoff() async {
        let samsung = Stock(
            stockCode: "005930",
            stockName: "삼성전자",
            market: "KOSPI",
            currentPrice: 75_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
        let clock = TestClock()
        let connectionCount = LockIsolated(0)
        let store = TestStore(
            initialState: StockFeature.State(stocks: [samsung])
        ) {
            StockFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.stockClient.observeRealtimePrices = { _ in
                connectionCount.withValue { $0 += 1 }

                if connectionCount.value == 1 {
                    // 첫 연결은 즉시 종료되어 재연결 흐름을 일으킨다.
                    return AsyncThrowingStream { $0.finish() }
                }

                return .never
            }
        }

        await store.send(.startRealtimeUpdates)
        await store.receive(.realtimeStreamFailed) {
            $0.realtimeRetryCount = 1
        }

        await clock.advance(by: .seconds(1))
        await store.receive(.startRealtimeUpdates)
        XCTAssertEqual(connectionCount.value, 2)

        await store.send(.onDisappear)
    }

    func testStockFeatureStartRealtimeUpdatesDoesNothingWhenStocksIsEmpty() async {
        let store = TestStore(initialState: StockFeature.State()) {
            StockFeature()
        }

        await store.send(.startRealtimeUpdates)
    }

    func testRealtimeRetryDelayBacksOffExponentiallyWithCap() {
        XCTAssertEqual(StockFeature.realtimeRetryDelay(retryCount: 1), 1)
        XCTAssertEqual(StockFeature.realtimeRetryDelay(retryCount: 2), 2)
        XCTAssertEqual(StockFeature.realtimeRetryDelay(retryCount: 3), 4)
        XCTAssertEqual(StockFeature.realtimeRetryDelay(retryCount: 6), 30)
        XCTAssertEqual(StockFeature.realtimeRetryDelay(retryCount: 100), 30)
    }

    func testStockFeatureShowsErrorMessageWhenLoadingFails() async {
        struct TestError: Error {}

        let store = TestStore(initialState: StockFeature.State()) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStockRankings = { _, _, _, _ in
                throw TestError()
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.stocksFailed("종목 랭킹을 불러오지 못했습니다.")) {
            $0.isLoading = false
            $0.errorMessage = "종목 랭킹을 불러오지 못했습니다."
        }
    }
}

private struct StubStockDataSource: StockDataSource {
    var fetchStocksHandler: @Sendable (
        _ market: StockMarket,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPageResponseDTO = { _, _, _ in
        StockPageResponseDTO(stocks: [], page: 0, size: 30, hasNext: false)
    }
    var fetchStockRankingsHandler: @Sendable (
        _ market: StockMarket,
        _ type: StockRankingType,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPageResponseDTO = { _, _, _, _ in
        StockPageResponseDTO(stocks: [], page: 0, size: 30, hasNext: false)
    }
    var fetchStockHandler: @Sendable (_ stockCode: String) async throws -> StockResponseDTO = { stockCode in
        StockResponseDTO(
            stockCode: stockCode,
            stockName: "테스트",
            market: "KOSPI",
            currentPrice: 1_000,
            changePrice: nil,
            changeRate: nil,
            tradeVolume: nil,
            tradeAmount: nil,
            priceChangedAt: "2026-05-13T15:30:00"
        )
    }
    var observeRealtimePricesHandler: @Sendable (
        _ stockCodes: [String]
    ) -> AsyncThrowingStream<StockRealtimeEventDTO, Error> = { _ in .never }

    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO {
        try await fetchStocksHandler(market, page, size)
    }

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO {
        try await fetchStockRankingsHandler(market, type, page, size)
    }

    func fetchStock(stockCode: String) async throws -> StockResponseDTO {
        try await fetchStockHandler(stockCode)
    }

    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEventDTO, Error> {
        observeRealtimePricesHandler(stockCodes)
    }
}

private struct StubStockRepository: StockRepository {
    var fetchStocksHandler: @Sendable (
        _ market: StockMarket,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPage = { _, _, _ in
        StockPage(stocks: [], page: 0, hasNext: false)
    }
    var fetchStockRankingsHandler: @Sendable (
        _ market: StockMarket,
        _ type: StockRankingType,
        _ page: Int,
        _ size: Int
    ) async throws -> StockPage = { _, _, _, _ in
        StockPage(stocks: [], page: 0, hasNext: false)
    }
    var fetchStockHandler: @Sendable (_ stockCode: String) async throws -> Stock = { stockCode in
        Stock(
            stockCode: stockCode,
            stockName: "테스트",
            market: "KOSPI",
            currentPrice: 1_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
    }
    var observeRealtimePricesHandler: @Sendable (
        _ stockCodes: [String]
    ) -> AsyncThrowingStream<StockRealtimeEvent, Error> = { _ in .never }

    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPage {
        try await fetchStocksHandler(market, page, size)
    }

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPage {
        try await fetchStockRankingsHandler(market, type, page, size)
    }

    func fetchStock(stockCode: String) async throws -> Stock {
        try await fetchStockHandler(stockCode)
    }

    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEvent, Error> {
        observeRealtimePricesHandler(stockCodes)
    }
}
