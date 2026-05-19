import Foundation

/// 네트워크 요청을 보내기 전에 `URLRequest`를 수정하는 역할.
public protocol RequestAdapter: Sendable {
    /// 요청 전 공통 헤더, 인증 헤더, timeout 등 필요한 값을 반영한 요청을 반환.
    func adapt(_ urlRequest: URLRequest) async throws -> URLRequest
}
