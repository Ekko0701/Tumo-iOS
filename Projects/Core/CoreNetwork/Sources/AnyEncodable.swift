public struct AnyEncodable: Encodable, Sendable {
    private let encodeValue: @Sendable (Encoder) throws -> Void

    public init<Value: Encodable & Sendable>(_ value: Value) {
        self.encodeValue = value.encode(to:)
    }

    public func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
