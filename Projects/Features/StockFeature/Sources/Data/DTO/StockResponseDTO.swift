import Foundation

/// 종목 단건 응답. 등락/거래 필드는 시세(StockPrice)가 없으면 null로 내려온다.
struct StockResponseDTO: Decodable, Sendable, Equatable {
    let stockCode: String
    let stockName: String
    let market: String
    let currentPrice: Int
    let changePrice: Int?
    let changeRate: Decimal?
    let tradeVolume: Int?
    let tradeAmount: Int?
    let priceChangedAt: String
}
