/// 주문내역 1건.
public struct OrderHistoryItem: Equatable, Sendable, Identifiable {
    public var id: Int { orderId }
    public let orderId: Int
    public let stockCode: String
    public let stockName: String
    public let orderType: String   // "BUY" | "SELL"
    public let quantity: Int
    public let executedPrice: Int
    public let totalAmount: Int
    public let realizedProfit: Int?
    public let executedAt: String

    public init(orderId: Int, stockCode: String, stockName: String, orderType: String, quantity: Int, executedPrice: Int, totalAmount: Int, realizedProfit: Int?, executedAt: String) {
        self.orderId = orderId
        self.stockCode = stockCode
        self.stockName = stockName
        self.orderType = orderType
        self.quantity = quantity
        self.executedPrice = executedPrice
        self.totalAmount = totalAmount
        self.realizedProfit = realizedProfit
        self.executedAt = executedAt
    }
}

/// 주문내역 한 페이지(slice).
public struct OrderPage: Equatable, Sendable {
    public let items: [OrderHistoryItem]
    public let page: Int
    public let hasNext: Bool

    public init(items: [OrderHistoryItem], page: Int, hasNext: Bool) {
        self.items = items
        self.page = page
        self.hasNext = hasNext
    }
}
