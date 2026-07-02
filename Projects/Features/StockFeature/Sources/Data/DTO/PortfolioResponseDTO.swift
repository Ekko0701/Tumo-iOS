import Foundation

/// `GET /api/v1/portfolio` 응답.
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

    let cashBalance: Int
    let totalStockValue: Int
    let totalAsset: Int
    let profitAmount: Int
    let profitRate: Double
    let holdings: [PortfolioHoldingDTO]
}
