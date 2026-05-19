/// API 요청에서 사용하는 파라미터 타입.
///
/// Alamofire의 최신 `Parameters` 타입처럼 value를 `any Sendable`로 열어두어
/// `String`, `Int`, `Double`, `Bool`, 배열 등 다양한 요청 값을 담을 수 있게 한다.
public typealias Parameters = [String: any Sendable]
