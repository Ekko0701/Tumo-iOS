/// 실시간 체결가 stream에서 발생하는 이벤트.
public enum StockRealtimeEvent: Equatable, Sendable {
    /// SSE 연결이 맺어져 첫 이벤트(heartbeat 포함)를 수신했음을 알린다.
    /// 연결이 살아있다는 증거이므로 재연결 backoff 리셋의 근거가 된다.
    case connected
    /// 단일 종목의 체결가가 갱신됐다.
    case priceUpdated(StockPriceUpdate)
}
