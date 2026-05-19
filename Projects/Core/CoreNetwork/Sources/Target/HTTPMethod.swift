/// HTTP 요청 메서드.
///
/// `URLRequest.httpMethod`에 넣을 수 있도록 원시값을 표준 HTTP 메서드 문자열로 정의.
public enum HTTPMethod: String, Sendable {
    /// 서버에서 리소스를 조회할 때 사용.
    case get = "GET"

    /// 서버에 새 리소스를 생성하거나 명령성 요청을 보낼 때 사용.
    case post = "POST"

    /// 리소스 전체를 교체할 때 사용.
    case put = "PUT"

    /// 리소스 일부를 수정할 때 사용.
    case patch = "PATCH"

    /// 리소스를 삭제할 때 사용.
    case delete = "DELETE"
}
