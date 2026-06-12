/// SSE stream에서 수신한 하나의 이벤트.
public struct SseEvent: Equatable, Sendable {
    /// `event:` 필드 값. 서버가 이벤트 이름을 지정하지 않으면 nil.
    public let name: String?

    /// `data:` 필드 값. data 라인이 여러 개면 개행으로 합쳐진다.
    public let data: String

    public init(name: String?, data: String) {
        self.name = name
        self.data = data
    }
}
