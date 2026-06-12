import Foundation
import TumoNetwork

/// StockFeature에서 호출하는 종목 API endpoint.
enum StockAPI: TargetType {
    case stocks(market: StockMarket, page: Int, size: Int)
    case rankings(market: StockMarket, type: StockRankingType, page: Int, size: Int)
    case stock(stockCode: String)
    case realtimePriceStream(stockCodes: [String])

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

        case .realtimePriceStream:
            "/api/v1/stocks/realtime/prices/stream"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .stocks, .rankings, .stock, .realtimePriceStream:
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

        case .realtimePriceStream(let stockCodes):
            // Spring `@RequestParam List<String>`는 comma 구분 값을 리스트로 받는다.
            .requestParameters(
                ["stockCodes": stockCodes.joined(separator: ",")],
                encoding: .url
            )
        }
    }
}
