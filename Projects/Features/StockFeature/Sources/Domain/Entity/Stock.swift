import Foundation

public struct Stock: Equatable, Sendable, Identifiable {
    public var id: String {
        stockCode
    }

    public let stockCode: String
    public let stockName: String
    public let market: String
    public let currentPrice: Int
    /// 전일 대비 가격 변화량. 시세 정보가 없으면 nil.
    public let changePrice: Int?
    /// 전일 대비 가격 변화율(%). 시세 정보가 없으면 nil.
    public let changeRate: Decimal?
    /// 누적 거래량. 시세 정보가 없으면 nil.
    public let tradeVolume: Int?
    /// 누적 거래대금. 시세 정보가 없으면 nil.
    public let tradeAmount: Int?
    public let priceChangedAt: String

    public init(
        stockCode: String,
        stockName: String,
        market: String,
        currentPrice: Int,
        changePrice: Int? = nil,
        changeRate: Decimal? = nil,
        tradeVolume: Int? = nil,
        tradeAmount: Int? = nil,
        priceChangedAt: String
    ) {
        self.stockCode = stockCode
        self.stockName = stockName
        self.market = market
        self.currentPrice = currentPrice
        self.changePrice = changePrice
        self.changeRate = changeRate
        self.tradeVolume = tradeVolume
        self.tradeAmount = tradeAmount
        self.priceChangedAt = priceChangedAt
    }
}
