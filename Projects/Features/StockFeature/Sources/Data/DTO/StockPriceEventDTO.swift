import Foundation

/// 실시간 체결가 SSE `stock-price` 이벤트 응답.
struct StockPriceEventDTO: Decodable, Sendable, Equatable {
    /// 이벤트에 포함된 종목 가격 상태.
    struct StockPriceDTO: Decodable, Sendable, Equatable {
        let stockCode: String
        let currentPrice: Int
        let changePrice: Int?
        let changeRate: Decimal?
        let tradeVolume: Int?
        let tradeAmount: Int?
        let priceChangedAt: String
    }

    let price: StockPriceDTO
    let provider: String
    let receivedAt: String
}
