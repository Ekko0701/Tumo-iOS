/// API 요청에서 파라미터와 본문을 어떤 방식으로 구성할지 표현하는 타입.
///
/// Moya의 `Task` 개념을 Tumo 프로젝트에 필요한 범위만 작게 가져온 구조.
/// 이후 `Provider`가 이 값을 해석해 `URLRequest`의 query, body 등을 채운다.
public enum Task: Sendable {
    /// query parameter와 HTTP body가 없는 요청.
    ///
    /// 예: 단순 목록 조회, 내 정보 조회처럼 URL과 method만으로 충분한 API.
    case requestPlain

    /// `Encodable` 요청 DTO를 JSON body로 보내는 요청.
    ///
    /// 예: 로그인, 회원가입처럼 request body에 구조화된 JSON을 보내는 API.
    case requestJSONEncodable(AnyEncodable)

    /// 파라미터를 지정한 방식으로 인코딩하는 요청.
    ///
    /// `encoding`이 `.url`이면 query string, `.json`이면 JSON body로 변환.
    case requestParameters(Parameters, encoding: ParameterEncoding)
}
