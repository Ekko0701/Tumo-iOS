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

    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEvent, Error> {
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

    func observeOrderBook(stockCode: String) -> AsyncThrowingStream<StockOrderBookEvent, Error> {
        let events = stockDataSource.observeOrderBook(stockCode: stockCode)

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

    func fetchHolding(stockCode: String) async throws -> StockHolding? {
        let responseDTO = try await stockDataSource.fetchPortfolio()

        return responseDTO.holdings
            .first { $0.stockCode == stockCode }
            .map { $0.toEntity() }
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

private extension StockRealtimeEventDTO {
    func toEntity() -> StockRealtimeEvent {
        switch self {
        case .connected:
            .connected
        case .price(let dto):
            .priceUpdated(dto.toEntity())
        }
    }
}

private extension StockOrderBookEventDTO {
    func toEntity() -> StockOrderBookEvent {
        switch self {
        case .connected:
            .connected
        case .orderBook(let dto):
            .updated(dto.toEntity())
        }
    }
}

private extension StockOrderBookPayloadDTO {
    func toEntity() -> StockOrderBook {
        StockOrderBook(
            stockCode: orderBook.stockCode,
            askLevels: orderBook.askLevels.map { StockOrderBookLevel(price: $0.price, volume: $0.volume) },
            bidLevels: orderBook.bidLevels.map { StockOrderBookLevel(price: $0.price, volume: $0.volume) },
            orderBookChangedAt: orderBook.orderBookChangedAt
        )
    }
}

private extension PortfolioResponseDTO.PortfolioHoldingDTO {
    func toEntity() -> StockHolding {
        StockHolding(
            stockCode: stockCode,
            stockName: stockName,
            quantity: quantity,
            averagePrice: averagePrice,
            currentPrice: currentPrice,
            evaluationAmount: evaluationAmount,
            profitAmount: profitAmount,
            profitRate: profitRate
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
