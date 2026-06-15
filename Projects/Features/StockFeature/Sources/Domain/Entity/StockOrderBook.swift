import Foundation

/// 단일 종목의 실시간 호가창 상태.
public struct StockOrderBook: Equatable, Sendable {
    public let stockCode: String
    /// 매도호가 레벨. 백엔드가 가격 순으로 정렬해 내려준다.
    public let askLevels: [StockOrderBookLevel]
    /// 매수호가 레벨. 백엔드가 가격 순으로 정렬해 내려준다.
    public let bidLevels: [StockOrderBookLevel]
    public let orderBookChangedAt: String

    public init(
        stockCode: String,
        askLevels: [StockOrderBookLevel],
        bidLevels: [StockOrderBookLevel],
        orderBookChangedAt: String
    ) {
        self.stockCode = stockCode
        self.askLevels = askLevels
        self.bidLevels = bidLevels
        self.orderBookChangedAt = orderBookChangedAt
    }
}

/// 호가창의 한 가격 레벨(가격 + 잔량).
public struct StockOrderBookLevel: Equatable, Sendable {
    public let price: Int
    public let volume: Int

    public init(price: Int, volume: Int) {
        self.price = price
        self.volume = volume
    }
}
