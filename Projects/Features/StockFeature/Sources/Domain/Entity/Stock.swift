public struct Stock: Equatable, Sendable, Identifiable {
    public var id: String {
        stockCode
    }

    public let stockCode: String
    public let stockName: String
    public let market: String
    public let currentPrice: Int
    public let priceChangedAt: String

    public init(
        stockCode: String,
        stockName: String,
        market: String,
        currentPrice: Int,
        priceChangedAt: String
    ) {
        self.stockCode = stockCode
        self.stockName = stockName
        self.market = market
        self.currentPrice = currentPrice
        self.priceChangedAt = priceChangedAt
    }
}
