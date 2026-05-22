import Foundation
import TumoNetwork

/// StockFeature에서 호출하는 종목 API endpoint.
enum StockAPI: TargetType {
    case stocks
    case stock(stockCode: String)

    var baseURL: URL {
        URL(string: "http://localhost:8080")!
    }

    var path: String {
        switch self {
        case .stocks:
            "/api/v1/stocks"

        case .stock(let stockCode):
            "/api/v1/stocks/\(stockCode)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .stocks, .stock:
            .get
        }
    }

    var task: Task {
        switch self {
        case .stocks, .stock:
            .requestPlain
        }
    }
}
