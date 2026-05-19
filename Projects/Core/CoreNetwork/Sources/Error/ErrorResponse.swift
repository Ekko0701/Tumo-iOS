/// Tumo Backend의 공통 에러 응답.
///
/// 서버가 4xx/5xx 응답과 함께 내려주는 `code`, `message`, `fieldErrors`를 표현한다.
public struct ErrorResponse: Decodable, Equatable, Sendable {
    /// 서버에서 정의한 에러 코드.
    ///
    /// 예: `DUPLICATED_EMAIL`, `INVALID_LOGIN`, `INVALID_INPUT_VALUE`
    public let code: String

    /// 사용자에게 보여줄 수 있는 에러 메시지.
    public let message: String

    /// 필드 단위 검증 실패 목록.
    ///
    /// 예: 회원가입 요청에서 `email`, `password`, `nickname` 검증에 실패한 경우.
    public let fieldErrors: [FieldError]

    public init(
        code: String,
        message: String,
        fieldErrors: [FieldError]
    ) {
        self.code = code
        self.message = message
        self.fieldErrors = fieldErrors
    }

    public struct FieldError: Decodable, Equatable, Sendable {
        /// 검증에 실패한 필드 이름.
        public let field: String

        /// 해당 필드에 대한 에러 메시지.
        public let message: String

        public init(
            field: String,
            message: String
        ) {
            self.field = field
            self.message = message
        }
    }
}
