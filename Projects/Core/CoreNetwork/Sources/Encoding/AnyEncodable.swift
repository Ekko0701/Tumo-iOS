/// 구체 타입을 숨기고 `Encodable` 값으로만 다룰 수 있게 만드는 타입 소거 래퍼.
///
/// `Task.requestJSONEncodable`처럼 여러 종류의 요청 DTO를 하나의 타입으로 보관해야 할 때 사용.
/// 실제 인코딩 시점에는 초기화 때 전달받은 원본 값의 `encode(to:)`를 다시 호출.
public struct AnyEncodable: Encodable, Sendable {
    /// 원본 `Encodable` 값의 `encode(to:)` 호출을 보관하는 클로저.
    private let encodeValue: @Sendable (Encoder) throws -> Void

    /// `Encodable`과 `Sendable`을 만족하는 요청 DTO를 타입 소거 형태로 감싼다.
    public init<Value: Encodable & Sendable>(_ value: Value) {
        self.encodeValue = value.encode(to:)
    }

    /// `JSONEncoder` 등이 `AnyEncodable`을 인코딩할 때 호출되는 메서드.
    ///
    /// 이 메서드는 직접 필드를 인코딩하지 않고, 보관해 둔 원본 값의 인코딩 로직에 위임.
    public func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
