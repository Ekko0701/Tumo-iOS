/// 백엔드 주문 API 응답을 디코딩하는 DTO.
struct OrderResponseDTO: Decodable, Sendable {
    let orderId: Int
    let stockCode: String
    let stockName: String
    let orderType: String
    let quantity: Int
    let executedPrice: Int
    let totalAmount: Int
    let cashBalance: Int
    let executedAt: String
}
