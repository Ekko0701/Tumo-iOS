/// 실시간 호가 stream에서 발생하는 이벤트.
public enum StockOrderBookEvent: Equatable, Sendable {
    /// SSE 연결이 맺어져 첫 이벤트(heartbeat 포함)를 수신했음을 알린다.
    /// 연결이 살아있다는 증거이므로 재연결 backoff 리셋의 근거가 된다.
    case connected
    /// 호가창이 갱신됐다.
    case updated(StockOrderBook)
}
