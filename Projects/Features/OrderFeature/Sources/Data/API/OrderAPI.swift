import Foundation
import TumoNetwork

/// OrderFeature에서 호출하는 주문 API endpoint.
enum OrderAPI: TargetType {
    case buy(stockCode: String, quantity: Int)
    case sell(stockCode: String, quantity: Int)
    case orderHistory(page: Int, size: Int)

    var baseURL: URL {
        TumoBackend.baseURL
    }

    var path: String {
        switch self {
        case .buy, .sell, .orderHistory:
            "/api/v1/orders"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .buy, .sell:
            .post
        case .orderHistory:
            .get
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
        case .sell(let stockCode, let quantity):
            let params: Parameters = [
                "stockCode": stockCode,
                "quantity": quantity,
                "orderType": "SELL"
            ]
            return .requestParameters(params, encoding: .json)
        case .orderHistory(let page, let size):
            let params: Parameters = [
                "page": page,
                "size": size
            ]
            return .requestParameters(params, encoding: .url)
        }
    }
}
