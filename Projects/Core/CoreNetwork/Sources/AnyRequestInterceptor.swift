import Foundation

/// 클로저로 요청 수정과 재시도 판단을 주입할 수 있는 타입 소거 인터셉터.
public struct AnyRequestInterceptor: RequestInterceptor {
    private let adaptRequest: @Sendable (URLRequest) async throws -> URLRequest
    private let retryRequest: @Sendable (URLRequest, Error, HTTPURLResponse?) async throws -> RetryResult

    public init(
        adapt: @escaping @Sendable (URLRequest) async throws -> URLRequest = { $0 },
        retry: @escaping @Sendable (URLRequest, Error, HTTPURLResponse?) async throws -> RetryResult = { _, _, _ in .doNotRetry }
    ) {
        self.adaptRequest = adapt
        self.retryRequest = retry
    }

    public func adapt(_ urlRequest: URLRequest) async throws -> URLRequest {
        try await adaptRequest(urlRequest)
    }

    public func retry(
        _ urlRequest: URLRequest,
        dueTo error: Error,
        response: HTTPURLResponse?
    ) async throws -> RetryResult {
        try await retryRequest(urlRequest, error, response)
    }
}
