import Foundation

/// `TargetType`을 실제 HTTP 요청으로 실행하는 CoreNetwork의 기본 Provider.
///
/// Moya의 Provider처럼 `TargetType`으로 endpoint를 선언하고,
/// Provider가 `URLRequest` 생성, body/query 인코딩, URLSession 호출, 응답 검증을 담당한다.
public struct Provider<Target: TargetType>: Sendable {
    /// 실제 네트워크 요청을 수행하는 URLSession.
    private let urlSession: URLSession

    /// 요청 전 수정과 실패 후 재시도 판단을 수행하는 인터셉터 목록.
    private let interceptors: [any RequestInterceptor]

    /// 하나의 요청에서 허용할 최대 재시도 횟수.
    private let maxRetryCount: Int

    /// Provider 생성.
    ///
    /// - Parameters:
    ///   - urlSession: 실제 HTTP 요청에 사용할 URLSession.
    ///   - interceptors: 요청 수정, 인증 헤더 추가, 재시도 판단 등에 사용할 인터셉터 목록.
    ///   - maxRetryCount: 동일 요청의 최대 재시도 횟수.
    public init(
        urlSession: URLSession = .shared,
        interceptors: [any RequestInterceptor] = [],
        maxRetryCount: Int = 1
    ) {
        self.urlSession = urlSession
        self.interceptors = interceptors
        self.maxRetryCount = maxRetryCount
    }

    /// target을 요청하고 응답 body를 `Decodable` 모델로 변환.
    ///
    /// DataSource에서는 보통 이 메서드를 사용해 API 응답 DTO로 디코딩한다.
    public func request<Response: Decodable & Sendable>(
        _ target: Target,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await requestData(target)

        return try JSONDecoder().decode(responseType, from: data)
    }

    /// target을 요청하고 응답 body를 raw `Data`로 반환.
    ///
    /// `TargetType`을 `URLRequest`로 변환한 뒤 실제 요청 흐름은 `perform`에 위임한다.
    public func requestData(_ target: Target) async throws -> Data {
        let urlRequest = try makeURLRequest(from: target)

        return try await perform(urlRequest, retryCount: 0)
    }

    /// 하나의 URLRequest를 실행하고, 실패하면 인터셉터를 통해 재시도 여부를 판단한다.
    ///
    /// 이 메서드는 재시도 횟수를 함께 관리하므로 외부 공개 API와 분리한다.
    private func perform(
        _ urlRequest: URLRequest,
        retryCount: Int
    ) async throws -> Data {
        let result: Result<(Data, HTTPURLResponse), Error>

        do {
            // URLSession 자체가 실패하는 경우를 retry 흐름으로 보내기 위해 Result로 감싼다.
            result = .success(try await execute(urlRequest))
        } catch {
            result = .failure(error)
        }

        switch result {
        case .success(let (data, httpResponse)):
            do {
                // URLSession 요청은 성공했더라도 HTTP status code가 실패일 수 있다.
                try validateStatusCode(httpResponse.statusCode, data: data)
                return data
            } catch {
                return try await retryOrThrow(
                    urlRequest,
                    dueTo: error,
                    response: httpResponse,
                    retryCount: retryCount
                )
            }

        case .failure(let error):
            return try await retryOrThrow(
                urlRequest,
                dueTo: error,
                response: nil,
                retryCount: retryCount
            )
        }
    }

    /// 인터셉터 적용이 끝난 URLRequest를 URLSession으로 실행한다.
    private func execute(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let adaptedRequest = try await adapt(urlRequest)
        let (data, response) = try await urlSession.data(for: adaptedRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        return (data, httpResponse)
    }

    /// 등록된 인터셉터의 adapter를 순서대로 적용한다.
    ///
    /// 예를 들어 첫 번째 인터셉터가 공통 헤더를 붙이고,
    /// 두 번째 인터셉터가 인증 헤더를 붙이는 식으로 체이닝할 수 있다.
    private func adapt(_ urlRequest: URLRequest) async throws -> URLRequest {
        var adaptedRequest = urlRequest

        for interceptor in interceptors {
            adaptedRequest = try await interceptor.adapt(adaptedRequest)
        }

        return adaptedRequest
    }

    /// 인터셉터에게 재시도 여부를 묻고, 재시도가 필요하면 같은 요청을 다시 수행한다.
    ///
    /// 재시도 시점에는 원본 URLRequest를 다시 `perform`에 넘긴다.
    /// 그러면 `execute` 내부에서 adapter가 다시 적용되므로,
    /// 토큰 갱신 후 새 accessToken을 Authorization 헤더에 반영할 수 있다.
    private func retryOrThrow(
        _ urlRequest: URLRequest,
        dueTo error: Error,
        response: HTTPURLResponse?,
        retryCount: Int
    ) async throws -> Data {
        guard retryCount < maxRetryCount else {
            throw error
        }

        for interceptor in interceptors {
            let retryResult = try await interceptor.retry(
                urlRequest,
                dueTo: error,
                response: response
            )

            switch retryResult {
            case .retry:
                return try await perform(urlRequest, retryCount: retryCount + 1)

            case .doNotRetry:
                continue
            }
        }

        throw error
    }

    /// TargetType 선언을 실제 URLRequest로 변환한다.
    ///
    /// baseURL, path, method, headers, task를 이 단계에서 하나의 URLRequest로 합친다.
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

    /// Target의 Task를 URLRequest에 반영한다.
    ///
    /// request body, query string, Content-Type 같은 요청 데이터 구성이 이 단계에서 결정된다.
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

    /// HTTP status code가 성공 범위인지 검증한다.
    ///
    /// 서버가 공통 에러 응답 형식으로 내려준 경우에는 `NetworkError.server`로 감싸고,
    /// 그렇지 않은 실패 status code는 `unacceptableStatusCode`로 처리한다.
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
