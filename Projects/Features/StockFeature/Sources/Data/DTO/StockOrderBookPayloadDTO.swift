import Foundation

/// 실시간 호가 SSE `stock-order-book` 이벤트 응답.
struct StockOrderBookPayloadDTO: Decodable, Sendable, Equatable {
    /// 이벤트에 포함된 호가창 상태.
    struct OrderBookDTO: Decodable, Sendable, Equatable {
        /// 단일 가격 레벨.
        struct LevelDTO: Decodable, Sendable, Equatable {
            let price: Int
            let volume: Int
        }

        let stockCode: String
        let askLevels: [LevelDTO]
        let bidLevels: [LevelDTO]
        let orderBookChangedAt: String
    }

    let orderBook: OrderBookDTO
    let provider: String
    let receivedAt: String
}
