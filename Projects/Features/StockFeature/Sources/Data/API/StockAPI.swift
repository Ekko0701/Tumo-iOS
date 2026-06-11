import Foundation
import TumoNetwork

/// StockFeature에서 호출하는 종목 API endpoint.
enum StockAPI: TargetType {
    case stocks(market: StockMarket, page: Int, size: Int)
    case rankings(market: StockMarket, type: StockRankingType, page: Int, size: Int)
    case stock(stockCode: String)

    var baseURL: URL {
        URL(string: "http://localhost:8080")!
    }

    var path: String {
        switch self {
        case .stocks:
            "/api/v1/stocks"

        case .rankings:
            "/api/v1/stocks/rankings"

        case .stock(let stockCode):
            "/api/v1/stocks/\(stockCode)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .stocks, .rankings, .stock:
            .get
        }
    }

    var task: Task {
        switch self {
        case .stocks(let market, let page, let size):
            .requestParameters(
                [
                    "market": market.rawValue,
                    "page": page,
                    "size": size
                ],
                encoding: .url
            )

        case .rankings(let market, let type, let page, let size):
            .requestParameters(
                [
                    "market": market.rawValue,
                    "type": type.rawValue,
                    "page": page,
                    "size": size
                ],
                encoding: .url
            )

        case .stock:
            .requestPlain
        }
    }
}
