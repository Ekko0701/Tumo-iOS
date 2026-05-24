/// 매수 주문 체결 결과를 나타내는 도메인 엔티티.
public struct Order: Equatable, Sendable {
    public let orderId: Int
    public let stockCode: String
    public let stockName: String
    public let orderType: String
    public let quantity: Int
    public let executedPrice: Int
    public let totalAmount: Int
    public let cashBalance: Int
    public let executedAt: String

    public init(
        orderId: Int,
        stockCode: String,
        stockName: String,
        orderType: String,
        quantity: Int,
        executedPrice: Int,
        totalAmount: Int,
        cashBalance: Int,
        executedAt: String
    ) {
        self.orderId = orderId
        self.stockCode = stockCode
        self.stockName = stockName
        self.orderType = orderType
        self.quantity = quantity
        self.executedPrice = executedPrice
        self.totalAmount = totalAmount
        self.cashBalance = cashBalance
        self.executedAt = executedAt
    }
}
