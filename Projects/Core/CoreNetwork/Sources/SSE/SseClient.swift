import Foundation

/// `TargetType` endpoint에 SSE(text/event-stream) 연결을 맺고 이벤트 stream을 제공하는 클라이언트.
///
/// `Provider`가 단발 HTTP 요청을 담당한다면, SseClient는 같은 TargetType 선언을
/// 장시간 유지되는 SSE 연결로 실행한다. 인터셉터 체인(인증 헤더 주입 등)을 동일하게 적용한다.
public struct SseClient: Sendable {
    /// 서버 SSE timeout(30분)보다 길게 잡아 idle 구간에서 클라이언트가 먼저 끊지 않도록 한다.
    private static let requestTimeoutSeconds: TimeInterval = 35 * 60

    private let urlSession: URLSession
    private let interceptors: [any RequestInterceptor]

    public init(
        urlSession: URLSession = .shared,
        interceptors: [any RequestInterceptor] = []
    ) {
        self.urlSession = urlSession
        self.interceptors = interceptors
    }

    /// target에 SSE 연결을 맺고 수신한 이벤트를 순서대로 방출한다.
    ///
    /// stream을 소비하는 Task가 취소되면 연결도 함께 종료된다.
    /// 서버가 연결을 닫으면 stream이 정상 종료(finish)된다.
    public func connect<Target: TargetType>(_ target: Target) -> AsyncThrowingStream<SseEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = _Concurrency.Task {
                do {
                    var urlRequest = try makeURLRequest(from: target)
                    urlRequest.timeoutInterval = Self.requestTimeoutSeconds
                    urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    for interceptor in interceptors {
                        urlRequest = try await interceptor.adapt(urlRequest)
                    }

                    let (bytes, response) = try await urlSession.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        throw NetworkError.unacceptableStatusCode(httpResponse.statusCode)
                    }

                    // URLSession.AsyncBytes.lines는 빈 줄을 건너뛰어 SSE 이벤트 경계(빈 줄)를
                    // 잃어버리므로, byte 단위로 직접 라인을 조립한다.
                    var parser = SseEventParser()
                    var lineBuffer: [UInt8] = []

                    for try await byte in bytes {
                        if byte == UInt8(ascii: "\n") {
                            let line = String(decoding: lineBuffer, as: UTF8.self)
                            lineBuffer.removeAll(keepingCapacity: true)

                            if let event = parser.feed(line: line) {
                                continuation.yield(event)
                            }
                        } else if byte != UInt8(ascii: "\r") {
                            lineBuffer.append(byte)
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// TargetType 선언을 SSE 연결용 URLRequest로 변환한다.
    private func makeURLRequest<Target: TargetType>(from target: Target) throws -> URLRequest {
        guard let url = URL(string: target.path, relativeTo: target.baseURL)?.absoluteURL else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = target.method.rawValue

        target.headers?.forEach { header in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        switch target.task {
        case .requestPlain:
            return urlRequest

        case .requestParameters(let parameters, let encoding):
            return try encoding.encode(urlRequest, parameters: parameters)

        case .requestJSONEncodable:
            throw NetworkError.invalidURL
        }
    }
}

/// SSE 텍스트 라인을 누적해 이벤트 단위로 변환하는 파서.
///
/// SSE 규약: `event:`/`data:` 필드 라인이 이어지다가 빈 줄에서 하나의 이벤트가 완성된다.
/// `:`로 시작하는 주석 라인과 알 수 없는 필드는 무시한다.
public struct SseEventParser: Sendable {
    private var eventName: String?
    private var dataLines: [String] = []

    public init() {}

    /// 한 라인을 누적하고, 빈 줄로 이벤트가 완성되면 그 이벤트를 반환한다.
    public mutating func feed(line: String) -> SseEvent? {
        if line.isEmpty {
            return flush()
        }

        if line.hasPrefix(":") {
            return nil
        }

        if let value = fieldValue(of: "event", in: line) {
            eventName = value
        } else if let value = fieldValue(of: "data", in: line) {
            dataLines.append(value)
        }

        return nil
    }

    private mutating func flush() -> SseEvent? {
        defer {
            eventName = nil
            dataLines = []
        }

        guard !dataLines.isEmpty else {
            return nil
        }

        return SseEvent(name: eventName, data: dataLines.joined(separator: "\n"))
    }

    private func fieldValue(of field: String, in line: String) -> String? {
        guard line.hasPrefix("\(field):") else {
            return nil
        }

        let value = line.dropFirst(field.count + 1)
        return value.hasPrefix(" ") ? String(value.dropFirst()) : String(value)
    }
}
