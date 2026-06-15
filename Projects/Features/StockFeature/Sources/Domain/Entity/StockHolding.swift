import Foundation

/// 사용자의 특정 종목 보유 현황(MY주식 탭에 표시).
public struct StockHolding: Equatable, Sendable {
    public let stockCode: String
    public let stockName: String
    /// 보유 수량.
    public let quantity: Int
    /// 평균 매입 단가.
    public let averagePrice: Int
    /// 현재가.
    public let currentPrice: Int
    /// 평가 금액(현재가 × 수량).
    public let evaluationAmount: Int
    /// 평가 손익((현재가 - 평단) × 수량).
    public let profitAmount: Int
    /// 평가 손익률(%).
    public let profitRate: Double

    public init(
        stockCode: String,
        stockName: String,
        quantity: Int,
        averagePrice: Int,
        currentPrice: Int,
        evaluationAmount: Int,
        profitAmount: Int,
        profitRate: Double
    ) {
        self.stockCode = stockCode
        self.stockName = stockName
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.currentPrice = currentPrice
        self.evaluationAmount = evaluationAmount
        self.profitAmount = profitAmount
        self.profitRate = profitRate
    }
}
