struct OrderHistoryItemDTO: Decodable, Sendable {
    let orderId: Int
    let stockCode: String
    let stockName: String
    let orderType: String
    let quantity: Int
    let executedPrice: Int
    let totalAmount: Int
    let realizedProfit: Int?
    let executedAt: String
}

struct OrderPageDTO: Decodable, Sendable {
    let orders: [OrderHistoryItemDTO]
    let page: Int
    let size: Int
    let hasNext: Bool
}
