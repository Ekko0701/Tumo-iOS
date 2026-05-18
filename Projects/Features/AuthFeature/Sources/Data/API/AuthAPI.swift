import CoreNetwork
import Foundation

/// AuthFeature에서 호출하는 인증 API endpoint.
///
/// 각 case는 하나의 백엔드 API를 의미하며, Provider가 이 값을 읽어 `URLRequest`를 생성한다.
enum AuthAPI: TargetType {
    case login(LoginRequest)
    case signup(SignupRequest)

    var baseURL: URL {
        URL(string: "http://localhost:8080")!
    }

    var path: String {
        switch self {
        case .login:
            "/api/v1/auth/login"

        case .signup:
            "/api/v1/auth/signup"
        }
    }

    var method: CoreNetwork.Method {
        switch self {
        case .login, .signup:
            .post
        }
    }

    var task: Task {
        switch self {
        case .login(let request):
            .requestJSONEncodable(AnyEncodable(request))

        case .signup(let request):
            .requestJSONEncodable(AnyEncodable(request))
        }
    }
}
