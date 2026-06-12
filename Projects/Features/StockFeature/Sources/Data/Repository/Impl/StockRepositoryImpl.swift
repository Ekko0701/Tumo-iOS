/// 종목 DataSource 응답 DTO를 Domain Entity로 변환하는 Repository 구현체.
struct StockRepositoryImpl: StockRepository {
    private let stockDataSource: any StockDataSource

    init(stockDataSource: any StockDataSource) {
        self.stockDataSource = stockDataSource
    }

    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPage {
        let responseDTO = try await stockDataSource.fetchStocks(
            market: market,
            page: page,
            size: size
        )

        return responseDTO.toEntity()
    }

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPage {
        let responseDTO = try await stockDataSource.fetchStockRankings(
            market: market,
            type: type,
            page: page,
            size: size
        )

        return responseDTO.toEntity()
    }

    func fetchStock(stockCode: String) async throws -> Stock {
        let responseDTO = try await stockDataSource.fetchStock(stockCode: stockCode)

        return responseDTO.toEntity()
    }

    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockPriceUpdate, Error> {
        let events = stockDataSource.observeRealtimePrices(stockCodes: stockCodes)

        return AsyncThrowingStream { continuation in
            let task = _Concurrency.Task {
                do {
                    for try await eventDTO in events {
                        continuation.yield(eventDTO.toEntity())
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

private extension StockPageResponseDTO {
    func toEntity() -> StockPage {
        StockPage(
            stocks: stocks.map { $0.toEntity() },
            page: page,
            hasNext: hasNext
        )
    }
}

private extension StockPriceEventDTO {
    func toEntity() -> StockPriceUpdate {
        StockPriceUpdate(
            stockCode: price.stockCode,
            currentPrice: price.currentPrice,
            changePrice: price.changePrice,
            changeRate: price.changeRate,
            tradeVolume: price.tradeVolume,
            tradeAmount: price.tradeAmount,
            priceChangedAt: price.priceChangedAt
        )
    }
}

private extension StockResponseDTO {
    func toEntity() -> Stock {
        Stock(
            stockCode: stockCode,
            stockName: stockName,
            market: market,
            currentPrice: currentPrice,
            changePrice: changePrice,
            changeRate: changeRate,
            tradeVolume: tradeVolume,
            tradeAmount: tradeAmount,
            priceChangedAt: priceChangedAt
        )
    }
}
