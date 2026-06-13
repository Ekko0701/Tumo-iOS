/// 실시간 체결가 SSE stream에서 발생하는 이벤트의 데이터 계층 표현.
enum StockRealtimeEventDTO: Equatable, Sendable {
    /// SSE 연결이 맺어져 첫 이벤트(heartbeat 포함)를 수신했다.
    case connected
    /// `stock-price` 이벤트를 수신했다.
    case price(StockPriceEventDTO)
}
