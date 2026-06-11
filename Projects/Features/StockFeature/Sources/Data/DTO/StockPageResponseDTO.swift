/// `GET /api/v1/stocks`, `GET /api/v1/stocks/rankings`의 page 응답.
struct StockPageResponseDTO: Decodable, Sendable, Equatable {
    let stocks: [StockResponseDTO]
    let page: Int
    let size: Int
    let hasNext: Bool
}
