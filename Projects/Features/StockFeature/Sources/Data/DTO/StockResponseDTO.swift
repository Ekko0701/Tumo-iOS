struct StockResponseDTO: Decodable, Sendable, Equatable {
    let stockCode: String
    let stockName: String
    let market: String
    let currentPrice: Int
    let priceChangedAt: String
}
