/// CoreNetwork에서 공통으로 사용하는 네트워크 에러.
public enum NetworkError: Error, Equatable, Sendable {
    /// `baseURL`과 `path`로 유효한 URL을 만들 수 없는 경우.
    case invalidURL

    /// `URLSession` 응답을 `HTTPURLResponse`로 변환할 수 없는 경우.
    case invalidResponse

    /// 서버가 2xx 범위를 벗어난 HTTP status code를 반환한 경우.
    case unacceptableStatusCode(Int)

    /// 서버가 공통 에러 응답을 반환한 경우.
    case server(ErrorResponse, statusCode: Int)
}
