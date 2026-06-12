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
                    XCTAssertEqual(type, .popular)
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
            type: .popular,
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
            $0.stockClient.fetchStocks = { _, _, _ in
                stockPage
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.stocksLoaded(stockPage)) {
            $0.isLoading = false
            $0.stocks = stocks
        }
    }

    func testStockFeatureLoadsNextPageWhenLastRowAppears() async {
        let firstPageStocks = [
            Stock(
                stockCode: "005930",
                stockName: "삼성전자",
                market: "KOSPI",
                currentPrice: 75_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        ]
        let secondPageStocks = [
            Stock(
                stockCode: "000660",
                stockName: "SK하이닉스",
                market: "KOSPI",
                currentPrice: 180_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        ]
        let secondPage = StockPage(stocks: secondPageStocks, page: 1, hasNext: false)
        let store = TestStore(
            initialState: StockFeature.State(
                stocks: firstPageStocks,
                currentPage: 0,
                hasNextPage: true
            )
        ) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStocks = { _, page, _ in
                XCTAssertEqual(page, 1)
                return secondPage
            }
        }

        await store.send(.rowAppeared(stockCode: "005930")) {
            $0.isLoadingNextPage = true
        }
        await store.receive(.nextPageLoaded(secondPage)) {
            $0.isLoadingNextPage = false
            $0.currentPage = 1
            $0.hasNextPage = false
            $0.stocks = firstPageStocks + secondPageStocks
        }
    }

    func testStockFeatureIgnoresRowAppearedWhenNotLastRowOrNoNextPage() async {
        let stocks = [
            Stock(
                stockCode: "005930",
                stockName: "삼성전자",
                market: "KOSPI",
                currentPrice: 75_000,
                priceChangedAt: "2026-05-13T15:30:00"
            ),
            Stock(
                stockCode: "000660",
                stockName: "SK하이닉스",
                market: "KOSPI",
                currentPrice: 180_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        ]

        // 마지막 행이 아니면 로드하지 않는다.
        let store = TestStore(
            initialState: StockFeature.State(
                stocks: stocks,
                currentPage: 0,
                hasNextPage: true
            )
        ) {
            StockFeature()
        }
        await store.send(.rowAppeared(stockCode: "005930"))

        // 다음 page가 없으면 마지막 행이어도 로드하지 않는다.
        let exhaustedStore = TestStore(
            initialState: StockFeature.State(
                stocks: stocks,
                currentPage: 0,
                hasNextPage: false
            )
        ) {
            StockFeature()
        }
        await exhaustedStore.send(.rowAppeared(stockCode: "000660"))
    }

    func testStockFeatureNextPageFailureKeepsExistingStocks() async {
        struct TestError: Error {}

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
            initialState: StockFeature.State(
                stocks: stocks,
                currentPage: 0,
                hasNextPage: true
            )
        ) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStocks = { _, _, _ in
                throw TestError()
            }
        }

        await store.send(.rowAppeared(stockCode: "005930")) {
            $0.isLoadingNextPage = true
        }
        await store.receive(.nextPageFailed) {
            $0.isLoadingNextPage = false
        }
        XCTAssertEqual(store.state.stocks, stocks)
        XCTAssertNil(store.state.errorMessage)
    }

    func testStockFeatureSortOptionChangedSortsDisplayedStocks() async {
        // 한글 자모 순서가 명확한 이름(가 < 마 < 바)으로 로캘 의존성을 제거한다.
        let ga = Stock(
            stockCode: "000001",
            stockName: "가온전자",
            market: "KOSPI",
            currentPrice: 50_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
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
        let store = TestStore(
            initialState: StockFeature.State(stocks: [ga, ma, ba])
        ) {
            StockFeature()
        }

        // 기본(.popular)은 원본 순서를 유지한다.
        XCTAssertEqual(store.state.displayedStocks, [ga, ma, ba])

        await store.send(.sortOptionChanged(.price)) {
            $0.sortOption = .price
        }
        // 가격 내림차순: 마루소프트(150,000) > 바다물산(100,000) > 가온전자(50,000)
        XCTAssertEqual(store.state.displayedStocks, [ma, ba, ga])

        await store.send(.sortOptionChanged(.name)) {
            $0.sortOption = .name
        }
        // 이름 오름차순: 가온전자 < 마루소프트 < 바다물산
        XCTAssertEqual(store.state.displayedStocks, [ga, ma, ba])
    }

    func testStockFeatureShowsErrorMessageWhenLoadingFails() async {
        struct TestError: Error {}

        let store = TestStore(initialState: StockFeature.State()) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStocks = { _, _, _ in
                throw TestError()
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.stocksFailed("종목 정보를 불러오지 못했습니다.")) {
            $0.isLoading = false
            $0.errorMessage = "종목 정보를 불러오지 못했습니다."
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
}
