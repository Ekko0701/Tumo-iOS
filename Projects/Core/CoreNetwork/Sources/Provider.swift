import Foundation

/// `TargetType`을 실제 HTTP 요청으로 실행하는 CoreNetwork의 기본 Provider.
///
/// Moya의 Provider처럼 `TargetType`으로 endpoint를 선언하고,
/// Provider가 `URLRequest` 생성, body/query 인코딩, URLSession 호출, 응답 검증을 담당한다.
public struct Provider<Target: TargetType>: Sendable {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// target을 요청하고 응답 body를 `Decodable` 모델로 변환.
    public func request<Response: Decodable & Sendable>(
        _ target: Target,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await requestData(target)

        return try JSONDecoder().decode(responseType, from: data)
    }

    /// target을 요청하고 응답 body를 raw `Data`로 반환.
    public func requestData(_ target: Target) async throws -> Data {
        let urlRequest = try makeURLRequest(from: target)
        let (data, response) = try await urlSession.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validateStatusCode(httpResponse.statusCode, data: data)

        return data
    }

    private func makeURLRequest(from target: Target) throws -> URLRequest {
        guard let url = URL(string: target.path, relativeTo: target.baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = target.method.rawValue

        target.headers?.forEach { header in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        return try applyTask(target.task, to: urlRequest)
    }

    private func applyTask(
        _ task: Task,
        to urlRequest: URLRequest
    ) throws -> URLRequest {
        switch task {
        case .requestPlain:
            return urlRequest

        case .requestJSONEncodable(let encodable):
            var encodedRequest = urlRequest
            encodedRequest.httpBody = try JSONEncoder().encode(encodable)
            encodedRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            return encodedRequest

        case .requestParameters(let parameters, let encoding):
            var encodedRequest = try encoding.encode(urlRequest, parameters: parameters)

            if encoding == .json {
                encodedRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            return encodedRequest
        }
    }

    private func validateStatusCode(
        _ statusCode: Int,
        data: Data
    ) throws {
        guard (200..<300).contains(statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.server(errorResponse, statusCode: statusCode)
            }

            throw NetworkError.unacceptableStatusCode(statusCode)
        }
    }
}
