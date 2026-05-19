/// 실패한 네트워크 요청을 다시 시도할지 나타내는 결과.
public enum RetryResult: Equatable, Sendable {
    /// 요청을 다시 시도하지 않음.
    case doNotRetry

    /// 동일한 요청을 다시 시도.
    case retry
}
