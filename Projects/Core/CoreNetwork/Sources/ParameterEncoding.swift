import Foundation

/// 파라미터를 `URLRequest`에 반영하는 방식.
///
/// GET 계열 요청은 보통 `.url`, POST/PUT/PATCH 계열 요청은 상황에 따라 `.json` 사용.
public enum ParameterEncoding: Sendable {
    /// 파라미터를 URL query string으로 인코딩.
    ///
    /// 예: `/stocks?market=KOSPI&keyword=삼성`
    case url

    /// 파라미터를 JSON body로 인코딩.
    ///
    /// 예: `{ "email": "user@example.com", "password": "password" }`
    case json

    /// 전달받은 `URLRequest`에 파라미터를 반영한 새 `URLRequest`를 반환.
    ///
    /// `URLRequest`는 값 타입이므로 원본을 직접 바꾸지 않고 복사본을 만들어 반환.
    public func encode(
        _ urlRequest: URLRequest,
        parameters: Parameters
    ) throws -> URLRequest {
        switch self {
        case .url:
            try encodeURL(urlRequest, parameters: parameters)

        case .json:
            try encodeJSON(urlRequest, parameters: parameters)
        }
    }

    private func encodeURL(
        _ urlRequest: URLRequest,
        parameters: Parameters
    ) throws -> URLRequest {
        // query string을 안전하게 조립하기 위해 URL 문자열을 직접 붙이지 않고 URLComponents를 사용.
        guard let url = urlRequest.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ParameterEncodingError.invalidURL
        }

        var encodedRequest = urlRequest
        let queryItems = parameters
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

        // 기존 query item이 있으면 유지하고, 새 파라미터를 뒤에 추가.
        components.queryItems = (components.queryItems ?? []) + queryItems
        encodedRequest.url = components.url

        return encodedRequest
    }

    private func encodeJSON(
        _ urlRequest: URLRequest,
        parameters: Parameters
    ) throws -> URLRequest {
        var encodedRequest = urlRequest
        let jsonObject = parameters.reduce(into: [String: Any]()) { result, parameter in
            result[parameter.key] = parameter.value
        }

        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            throw ParameterEncodingError.invalidJSONObject
        }

        // JSONSerialization이 Dictionary를 JSON data로 변환하고, 그 결과를 HTTP body에 설정.
        encodedRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)

        return encodedRequest
    }
}

/// 파라미터 인코딩 과정에서 발생할 수 있는 에러.
public enum ParameterEncodingError: Error, Equatable, Sendable {
    /// `URLRequest`에 유효한 URL이 없어 query string을 만들 수 없는 경우.
    case invalidURL

    /// 파라미터에 JSON으로 변환할 수 없는 값이 포함된 경우.
    case invalidJSONObject
}
