import Foundation

/// 실시간 체결가 이벤트로 수신한 단일 종목의 가격 변경.
public struct StockPriceUpdate: Equatable, Sendable {
    public let stockCode: String
    public let currentPrice: Int
    public let changePrice: Int?
    public let changeRate: Decimal?
    public let tradeVolume: Int?
    public let tradeAmount: Int?
    public let priceChangedAt: String

    public init(
        stockCode: String,
        currentPrice: Int,
        changePrice: Int? = nil,
        changeRate: Decimal? = nil,
        tradeVolume: Int? = nil,
        tradeAmount: Int? = nil,
        priceChangedAt: String
    ) {
        self.stockCode = stockCode
        self.currentPrice = currentPrice
        self.changePrice = changePrice
        self.changeRate = changeRate
        self.tradeVolume = tradeVolume
        self.tradeAmount = tradeAmount
        self.priceChangedAt = priceChangedAt
    }
}
