import Foundation
import TumoNetwork

/// 실제 백엔드 종목 API를 호출하는 DataSource 구현체.
struct StockDataSourceImpl: StockDataSource {
    private static let stockPriceEventName = "stock-price"

    private let provider: Provider<StockAPI>
    private let sseClient: SseClient

    init(provider: Provider<StockAPI>, sseClient: SseClient) {
        self.provider = provider
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

    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockPriceEventDTO, Error> {
        let events = sseClient.connect(StockAPI.realtimePriceStream(stockCodes: stockCodes))

        return AsyncThrowingStream { continuation in
            let task = _Concurrency.Task {
                do {
                    // heartbeat 등 다른 이벤트는 무시하고 체결가 이벤트만 DTO로 변환한다.
                    for try await event in events where event.name == Self.stockPriceEventName {
                        let dto = try JSONDecoder().decode(
                            StockPriceEventDTO.self,
                            from: Data(event.data.utf8)
                        )
                        continuation.yield(dto)
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
}
