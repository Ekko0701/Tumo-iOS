import Foundation
import TumoNetwork

/// 포트폴리오(보유 종목) 조회 API endpoint.
/// MY주식 탭에서 보유 현황을 표시하기 위해 사용한다. 인증이 필요하다.
enum PortfolioAPI: TargetType {
    case portfolio

    var baseURL: URL {
        TumoBackend.baseURL
    }

    var path: String {
        switch self {
        case .portfolio:
            "/api/v1/portfolio"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .portfolio:
            .get
        }
    }

    var task: Task {
        switch self {
        case .portfolio:
            .requestPlain
        }
    }
}
