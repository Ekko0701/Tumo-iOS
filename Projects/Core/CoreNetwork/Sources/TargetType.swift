import Foundation

/// 하나의 API endpoint를 표현하는 타입.
///
/// Feature 모듈은 직접 `URLRequest`를 만들지 않고, 이 프로토콜을 채택한 enum/struct로
/// baseURL, path, method, task, headers만 선언한다.
public protocol TargetType: Sendable {
    /// API 서버의 기본 URL.
    ///
    /// 예: `http://localhost:8080`
    var baseURL: URL { get }

    /// endpoint 경로.
    ///
    /// 예: `/api/v1/auth/login`
    var path: String { get }

    /// HTTP 요청 메서드.
    var method: HTTPMethod { get }

    /// 요청 body 또는 query parameter 구성 방식.
    var task: Task { get }

    /// 요청에 추가할 HTTP header.
    var headers: [String: String]? { get }
}

public extension TargetType {
    /// header가 필요 없는 endpoint를 위한 기본값.
    var headers: [String: String]? {
        nil
    }
}
