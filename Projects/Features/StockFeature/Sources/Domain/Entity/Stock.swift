struct Stock: Equatable, Sendable, Identifiable {
    var id: String {
        stockCode
    }

    let stockCode: String
    let stockName: String
    let market: String
    let currentPrice: Int
    let priceChangedAt: String
}
