import Foundation

/// 단일 캔들(OHLCV). 차트 탭에 표시한다.
public struct StockCandle: Equatable, Sendable, Identifiable {
    public var id: Date { candleTime }

    /// 캔들 기준 시각.
    public let candleTime: Date
    public let openPrice: Int
    public let highPrice: Int
    public let lowPrice: Int
    public let closePrice: Int
    public let tradeVolume: Int
    public let tradeAmount: Int

    public init(
        candleTime: Date,
        openPrice: Int,
        highPrice: Int,
        lowPrice: Int,
        closePrice: Int,
        tradeVolume: Int,
        tradeAmount: Int
    ) {
        self.candleTime = candleTime
        self.openPrice = openPrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.closePrice = closePrice
        self.tradeVolume = tradeVolume
        self.tradeAmount = tradeAmount
    }
}
