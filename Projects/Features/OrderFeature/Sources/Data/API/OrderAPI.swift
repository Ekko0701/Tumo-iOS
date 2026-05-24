import Foundation
import TumoNetwork

/// OrderFeature에서 호출하는 주문 API endpoint.
enum OrderAPI: TargetType {
    case buy(stockCode: String, quantity: Int)

    var baseURL: URL {
        URL(string: "http://localhost:8080")!
    }

    var path: String {
        switch self {
        case .buy:
            "/api/v1/orders"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .buy:
            .post
        }
    }

    var task: Task {
        switch self {
        case .buy(let stockCode, let quantity):
            let params: Parameters = [
                "stockCode": stockCode,
                "quantity": quantity,
                "orderType": "BUY"
            ]
            return .requestParameters(params, encoding: .json)
        }
    }
}
