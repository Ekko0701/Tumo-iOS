import Foundation

/// 네트워크 요청 실패 후 재시도 여부를 결정하는 역할.
public protocol RequestRetrier: Sendable {
    /// 실패한 요청, 발생한 에러, HTTP 응답을 바탕으로 재시도 여부를 반환.
    func retry(
        _ urlRequest: URLRequest,
        dueTo error: Error,
        response: HTTPURLResponse?
    ) async throws -> RetryResult
}
