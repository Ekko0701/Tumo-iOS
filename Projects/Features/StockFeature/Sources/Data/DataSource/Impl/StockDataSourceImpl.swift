import Foundation
import TumoNetwork

/// 실제 백엔드 종목 API를 호출하는 DataSource 구현체.
struct StockDataSourceImpl: StockDataSource {
    private static let stockPriceEventName = "stock-price"
    private static let stockOrderBookEventName = "stock-order-book"

    private let provider: Provider<StockAPI>
    private let portfolioProvider: Provider<PortfolioAPI>
    private let sseClient: SseClient

    init(
        provider: Provider<StockAPI>,
        portfolioProvider: Provider<PortfolioAPI>,
        sseClient: SseClient
    ) {
        self.provider = provider
        self.portfolioProvider = portfolioProvider
        self.sseClient = sseClient
    }

    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO {
        try await provider.request(
            .stocks(market: market, page: page, size: size),
            as: StockPageResponseDTO.self
        )
    }

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO {
        try await provider.request(
            .rankings(market: market, type: type, page: page, size: size),
            as: StockPageResponseDTO.self
        )
    }

    func fetchStock(stockCode: String) async throws -> StockResponseDTO {
        try await provider.request(
            .stock(stockCode: stockCode),
            as: StockResponseDTO.self
        )
    }

    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEventDTO, Error> {
        let events = sseClient.connect(StockAPI.realtimePriceStream(stockCodes: stockCodes))

        return AsyncThrowingStream { continuation in
            let task = _Concurrency.Task {
                do {
                    var didAnnounceConnection = false

                    for try await event in events {
                        // 첫 이벤트(heartbeat 포함)는 연결이 살아있다는 증거다.
                        // 재연결 backoff 리셋의 근거이므로 한 번만 알린다.
                        if !didAnnounceConnection {
                            didAnnounceConnection = true
                            continuation.yield(.connected)
                        }

                        // 체결가 이벤트만 가격 DTO로 변환한다. heartbeat 등은 연결 신호로만 쓴다.
                        guard event.name == Self.stockPriceEventName else {
                            continue
                        }

                        let dto = try JSONDecoder().decode(
                            StockPriceEventDTO.self,
                            from: Data(event.data.utf8)
                        )
                        continuation.yield(.price(dto))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func observeOrderBook(stockCode: String) -> AsyncThrowingStream<StockOrderBookEventDTO, Error> {
        let events = sseClient.connect(StockAPI.realtimeOrderBookStream(stockCode: stockCode))

        return AsyncThrowingStream { continuation in
            let task = _Concurrency.Task {
                do {
                    var didAnnounceConnection = false

                    for try await event in events {
                        // 첫 이벤트(heartbeat 포함)는 연결이 살아있다는 증거다.
                        // 재연결 backoff 리셋의 근거이므로 한 번만 알린다.
                        if !didAnnounceConnection {
                            didAnnounceConnection = true
                            continuation.yield(.connected)
                        }

                        // 호가 이벤트만 DTO로 변환한다. heartbeat 등은 연결 신호로만 쓴다.
                        guard event.name == Self.stockOrderBookEventName else {
                            continue
                        }

                        let dto = try JSONDecoder().decode(
                            StockOrderBookPayloadDTO.self,
                            from: Data(event.data.utf8)
                        )
                        continuation.yield(.orderBook(dto))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func fetchPortfolio() async throws -> PortfolioResponseDTO {
        try await portfolioProvider.request(
            .portfolio,
            as: PortfolioResponseDTO.self
        )
    }

    func fetchCandles(
        stockCode: String,
        interval: CandleInterval,
        from: String,
        to: String
    ) async throws -> StockCandleListResponseDTO {
        try await provider.request(
            .candles(stockCode: stockCode, interval: interval, from: from, to: to),
            as: StockCandleListResponseDTO.self
        )
    }
}
