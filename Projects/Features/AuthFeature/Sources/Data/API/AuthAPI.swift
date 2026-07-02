import TumoNetwork
import Foundation

/// AuthFeature에서 호출하는 인증 API endpoint.
///
/// 각 case는 하나의 백엔드 API를 의미하며, Provider가 이 값을 읽어 `URLRequest`를 생성한다.
enum AuthAPI: TargetType {
    case login(LoginRequestDTO)
    case signup(SignupRequestDTO)
    case refreshToken(TokenRefreshRequestDTO)

    var baseURL: URL {
        TumoBackend.baseURL
    }

    var path: String {
        switch self {
        case .login:
            "/api/v1/auth/login"

        case .signup:
            "/api/v1/auth/signup"

        case .refreshToken:
            "/api/v1/auth/token/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .signup, .refreshToken:
            .post
        }
    }

    var task: Task {
        switch self {
        case .login(let requestDTO):
            .requestJSONEncodable(AnyEncodable(requestDTO))

        case .signup(let requestDTO):
            .requestJSONEncodable(AnyEncodable(requestDTO))

        case .refreshToken(let requestDTO):
            .requestJSONEncodable(AnyEncodable(requestDTO))
        }
    }
}
