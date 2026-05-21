import TumoNetwork

/// 인증 API 호출 중 발생한 에러를 화면에 보여줄 메시지로 변환한다.
enum AuthErrorMessageMapper {
    static func message(from error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "요청 처리 중 오류가 발생했습니다."
        }

        switch networkError {
        case .server(let errorResponse, _):
            if let fieldError = errorResponse.fieldErrors.first {
                return fieldError.message
            }

            return errorResponse.message

        case .invalidURL:
            return "요청 URL이 올바르지 않습니다."

        case .invalidResponse:
            return "서버 응답을 확인할 수 없습니다."

        case .unacceptableStatusCode:
            return "서버 요청에 실패했습니다."
        }
    }
}
