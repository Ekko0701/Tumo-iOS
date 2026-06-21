import Foundation

/// SSE 스트림 재연결을 위한 지수 백오프 정책.
///
/// 연속 실패 횟수가 늘수록 재연결 대기 시간을 1→2→4→8→16초로 늘리고
/// 30초에서 상한을 둔다. 연결에 성공하면 호출부에서 실패 카운트를 0으로
/// 리셋해 다음 끊김은 다시 짧은 간격부터 시작하게 한다.
public enum SseReconnectBackoff {
    /// 백오프 대기 시간 상한(초).
    public static let maxDelaySeconds = 30

    /// 연속 실패 횟수에 대응하는 재연결 대기 시간(초)을 반환한다.
    ///
    /// - Parameter retryCount: 1 이상의 연속 실패 횟수.
    /// - Returns: `2^(retryCount-1)` 초, 단 `maxDelaySeconds` 상한.
    public static func delay(retryCount: Int) -> Int {
        let exponent = min(retryCount - 1, 5)
        return min(1 << max(exponent, 0), maxDelaySeconds)
    }
}
