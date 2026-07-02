import Foundation

/// 사용자의 포트폴리오 스냅샷(포트폴리오 탭에 표시).
public struct Portfolio: Equatable, Sendable {
    /// 현금 잔고.
    public let cashBalance: Int
    /// 보유 주식 평가 금액 합계.
    public let totalStockValue: Int
    /// 총 자산(현금 + 보유 주식 평가액).
    public let totalAsset: Int
    /// 전체 평가손익 금액.
    public let profitAmount: Int
    /// 전체 수익률(%).
    public let profitRate: Double
    /// 보유 종목 목록.
    public let holdings: [StockHolding]

    public init(
        cashBalance: Int,
        totalStockValue: Int,
        totalAsset: Int,
        profitAmount: Int,
        profitRate: Double,
        holdings: [StockHolding]
    ) {
        self.cashBalance = cashBalance
        self.totalStockValue = totalStockValue
        self.totalAsset = totalAsset
        self.profitAmount = profitAmount
        self.profitRate = profitRate
        self.holdings = holdings
    }
}
