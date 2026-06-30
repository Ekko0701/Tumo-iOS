import ComposableArchitecture
import XCTest
@testable import OrderFeature

@MainActor
final class OrderHistoryFeatureTests: XCTestCase {
    private func item(_ id: Int) -> OrderHistoryItem {
        OrderHistoryItem(orderId: id, stockCode: "005930", stockName: "삼성전자", orderType: "BUY",
                         quantity: 1, executedPrice: 75_000, totalAmount: 75_000, realizedProfit: nil,
                         executedAt: "2026-06-30T10:00:00")
    }

    func test_onAppear_loadsFirstPage() async {
        let page = OrderPage(items: [item(1), item(2)], page: 0, hasNext: true)
        let store = TestStore(initialState: OrderHistoryFeature.State()) { OrderHistoryFeature() }
        store.dependencies.orderClient.history = { _, _ in page }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.pageLoaded(page)) {
            $0.isLoading = false
            $0.items = [self.item(1), self.item(2)]
            $0.page = 0
            $0.hasNext = true
        }
    }

    func test_loadNextPage_appendsAndStopsWhenNoNext() async {
        let page1 = OrderPage(items: [item(3)], page: 1, hasNext: false)
        let store = TestStore(
            initialState: OrderHistoryFeature.State(items: [item(1), item(2)], page: 0, hasNext: true)
        ) { OrderHistoryFeature() }
        store.dependencies.orderClient.history = { _, _ in page1 }

        await store.send(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageLoaded(page1)) {
            $0.isLoading = false
            $0.items = [self.item(1), self.item(2), self.item(3)]
            $0.page = 1
            $0.hasNext = false
        }
        // hasNext=false 이후 추가 요청은 무시(네트워크 호출 없음)
        await store.send(.loadNextPage)
    }

    func test_loadFailed() async {
        struct Boom: Error {}
        let store = TestStore(initialState: OrderHistoryFeature.State()) { OrderHistoryFeature() }
        store.dependencies.orderClient.history = { _, _ in throw Boom() }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "주문 내역을 불러오지 못했습니다."
        }
    }
}
