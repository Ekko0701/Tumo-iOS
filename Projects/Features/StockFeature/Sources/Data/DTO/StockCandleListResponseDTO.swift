/// `GET /api/v1/stocks/{stockCode}/candles` 응답. 캔들은 시각 오름차순이다.
struct StockCandleListResponseDTO: Decodable, Sendable, Equatable {
    let stockCode: String
    let interval: String
    let candles: [StockCandleResponseDTO]
}
