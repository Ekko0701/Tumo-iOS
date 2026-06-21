import Foundation

/// 단일 캔들(OHLCV) 응답. `candleTime`은 타임존 없는 LocalDateTime 문자열
/// (예: `"2025-06-16T09:01:00"`)이며 Repository에서 KST 기준으로 파싱한다.
struct StockCandleResponseDTO: Decodable, Sendable, Equatable {
    let candleTime: String
    let openPrice: Int
    let highPrice: Int
    let lowPrice: Int
    let closePrice: Int
    let tradeVolume: Int
    let tradeAmount: Int
}
