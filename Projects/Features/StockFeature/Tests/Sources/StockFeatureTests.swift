import XCTest
import ComposableArchitecture
@testable import StockFeature

@MainActor
final class StockFeatureTests: XCTestCase {
    func testNamespace() {
        XCTAssertNotNil(StockFeatureNamespace.self)
    }

    func testStockRepositoryMapsListResponseDTOToEntities() async throws {
        let repository = StockRepositoryImpl(
            stockDataSource: StubStockDataSource(
                fetchStocksHandler: {
                    StockListResponseDTO(
                        stocks: [
                            StockResponseDTO(
                                stockCode: "005930",
                                stockName: "삼성전자",
                                market: "KOSPI",
                                currentPrice: 75_000,
                                priceChangedAt: "2026-05-13T15:30:00"
                            )
                        ]
                    )
                }
            )
        )

        let stocks = try await repository.fetchStocks()

        XCTAssertEqual(
            stocks,
            [
                Stock(
                    stockCode: "005930",
                    stockName: "삼성전자",
                    market: "KOSPI",
                    currentPrice: 75_000,
                    priceChangedAt: "2026-05-13T15:30:00"
                )
            ]
        )
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

    func testFetchStocksUsecaseReturnsRepositoryStocks() async throws {
        let expectedStocks = [
            Stock(
                stockCode: "035420",
                stockName: "NAVER",
                market: "KOSPI",
                currentPrice: 190_000,
                priceChangedAt: "2026-05-13T15:30:00"
            )
        ]
        let usecase = FetchStocksUsecaseImpl(
            stockRepository: StubStockRepository(
                fetchStocksHandler: {
                    expectedStocks
                }
            )
        )

        let stocks = try await usecase.execute()

        XCTAssertEqual(stocks, expectedStocks)
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
        let store = TestStore(initialState: StockFeature.State()) {
            StockFeature()
        } withDependencies: {
            $0.stockClient.fetchStocks = {
                stocks
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.stocksLoaded(stocks)) {
            $0.isLoading = false
            $0.stocks = stocks
        }
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
            $0.stockClient.fetchStocks = {
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
    var fetchStocksHandler: @Sendable () async throws -> StockListResponseDTO = {
        StockListResponseDTO(stocks: [])
    }
    var fetchStockHandler: @Sendable (_ stockCode: String) async throws -> StockResponseDTO = { stockCode in
        StockResponseDTO(
            stockCode: stockCode,
            stockName: "테스트",
            market: "KOSPI",
            currentPrice: 1_000,
            priceChangedAt: "2026-05-13T15:30:00"
        )
    }

    func fetchStocks() async throws -> StockListResponseDTO {
        try await fetchStocksHandler()
    }

    func fetchStock(stockCode: String) async throws -> StockResponseDTO {
        try await fetchStockHandler(stockCode)
    }
}

private struct StubStockRepository: StockRepository {
    var fetchStocksHandler: @Sendable () async throws -> [Stock] = {
        []
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

    func fetchStocks() async throws -> [Stock] {
        try await fetchStocksHandler()
    }

    func fetchStock(stockCode: String) async throws -> Stock {
        try await fetchStockHandler(stockCode)
    }
}
