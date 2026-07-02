import ComposableArchitecture
import CoreNetwork
import XCTest
@testable import OrderFeature

@MainActor
final class OrderSheetFeatureTests: XCTestCase {
    private func sampleOrder(_ type: String, realizedProfit: Int?) -> Order {
        Order(orderId: 1, stockCode: "005930", stockName: "삼성전자", orderType: type,
              quantity: 4, executedPrice: 80_000, totalAmount: 320_000,
              realizedProfit: realizedProfit, cashBalance: 9_680_000, executedAt: "2026-06-30T10:00:00")
    }

    func test_sell_success_setsResultAndEmitsDelegate() async {
        let order = sampleOrder("SELL", realizedProfit: 40_000)
        let store = TestStore(
            initialState: OrderSheetFeature.State(
                stockCode: "005930", stockName: "삼성전자", currentPrice: 80_000,
                mode: .sell, ownedQuantity: 10, quantityText: "4")
        ) { OrderSheetFeature() }
        store.dependencies.orderClient.sell = { _, _ in order }

        await store.send(.submitTapped) { $0.isSubmitting = true; $0.errorMessage = nil }
        await store.receive(.orderCompleted(order)) {
            $0.isSubmitting = false
            $0.result = order
        }
        await store.receive(.delegate(.orderCompleted(order)))
    }

    func test_invalidQuantity_showsError_noNetwork() async {
        let store = TestStore(
            initialState: OrderSheetFeature.State(
                stockCode: "005930", stockName: "삼성전자", currentPrice: 80_000,
                mode: .buy, ownedQuantity: 0, quantityText: "0")
        ) { OrderSheetFeature() }

        await store.send(.submitTapped) { $0.errorMessage = "주문 수량을 확인해주세요." }
    }

    func test_sellExceedingOwned_showsError() async {
        let store = TestStore(
            initialState: OrderSheetFeature.State(
                stockCode: "005930", stockName: "삼성전자", currentPrice: 80_000,
                mode: .sell, ownedQuantity: 3, quantityText: "5")
        ) { OrderSheetFeature() }

        await store.send(.submitTapped) { $0.errorMessage = "보유 수량을 초과했습니다." }
    }

    func test_failure_setsErrorMessage() async {
        struct Boom: Error {}
        let store = TestStore(
            initialState: OrderSheetFeature.State(
                stockCode: "005930", stockName: "삼성전자", currentPrice: 80_000,
                mode: .buy, ownedQuantity: 0, quantityText: "2")
        ) { OrderSheetFeature() }
        store.dependencies.orderClient.buy = { _, _ in throw Boom() }

        await store.send(.submitTapped) { $0.isSubmitting = true; $0.errorMessage = nil }
        await store.receive(.orderFailed("주문에 실패했습니다.")) {
            $0.isSubmitting = false
            $0.errorMessage = "주문에 실패했습니다."
        }
    }

    func test_serverError_usesServerMessage() async {
        let serverError = NetworkError.server(
            ErrorResponse(code: "INSUFFICIENT_HOLDING", message: "보유 수량이 부족합니다.", fieldErrors: []),
            statusCode: 400
        )
        let store = TestStore(
            initialState: OrderSheetFeature.State(
                stockCode: "005930", stockName: "삼성전자", currentPrice: 80_000,
                mode: .sell, ownedQuantity: 10, quantityText: "2")
        ) { OrderSheetFeature() }
        store.dependencies.orderClient.sell = { _, _ in throw serverError }

        await store.send(.submitTapped) { $0.isSubmitting = true; $0.errorMessage = nil }
        await store.receive(.orderFailed("보유 수량이 부족합니다.")) {
            $0.isSubmitting = false
            $0.errorMessage = "보유 수량이 부족합니다."
        }
    }
}
