import CoreNetwork
import Foundation

/// 저장된 accessToken을 요청의 Authorization 헤더에 주입하는 인터셉터.
///
/// 토큰 저장 방식은 클로저로 주입받는다.
/// 그래서 TumoNetwork는 Keychain의 세부 구현을 직접 알지 않고,
/// 매 요청 직전에 현재 저장된 최신 토큰만 읽어 사용할 수 있다.
public struct AuthTokenInterceptor: RequestInterceptor {
    private let loadAccessToken: @Sendable () throws -> String?

    public init(
        loadAccessToken: @escaping @Sendable () throws -> String?
    ) {
        self.loadAccessToken = loadAccessToken
    }

    public func adapt(_ urlRequest: URLRequest) async throws -> URLRequest {
        guard let accessToken = try loadAccessToken() else {
            return urlRequest
        }

        var request = urlRequest
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    public func retry(
        _ urlRequest: URLRequest,
        dueTo error: Error,
        response: HTTPURLResponse?
    ) async throws -> RetryResult {
        .doNotRetry
    }
}
