import Foundation

/// `GET /api/v1/portfolio` 응답. MY주식 탭에는 holdings만 사용하므로
/// 현금 잔고·총자산 등 다른 필드는 디코딩하지 않는다(JSON의 추가 키는 무시된다).
struct PortfolioResponseDTO: Decodable, Sendable, Equatable {
    /// 단일 보유 종목.
    struct PortfolioHoldingDTO: Decodable, Sendable, Equatable {
        let stockCode: String
        let stockName: String
        let quantity: Int
        let averagePrice: Int
        let currentPrice: Int
        let evaluationAmount: Int
        let profitAmount: Int
        let profitRate: Double
    }

    let holdings: [PortfolioHoldingDTO]
}
