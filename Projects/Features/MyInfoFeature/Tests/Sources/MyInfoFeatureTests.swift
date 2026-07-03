import AuthFeature
import ComposableArchitecture
import XCTest
@testable import MyInfoFeature

@MainActor
final class MyInfoFeatureTests: XCTestCase {
    private let user = AuthUser(id: 1, email: "a@b.com", nickname: "테스터", cashBalance: 10_000_000)

    func test_onAppear_loadsProfile() async {
        let store = TestStore(initialState: MyInfoFeature.State()) { MyInfoFeature() }
        let user = self.user
        store.dependencies.authClient.fetchMe = { user }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.profileLoaded(user)) {
            $0.isLoading = false
            $0.profile = user
        }
    }

    func test_onAppear_failureSetsError() async {
        struct Boom: Error {}
        let store = TestStore(initialState: MyInfoFeature.State()) { MyInfoFeature() }
        store.dependencies.authClient.fetchMe = { throw Boom() }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "내 정보를 불러오지 못했습니다."
        }
    }

    func test_logout_confirmSetsDidLogout() async {
        let store = TestStore(initialState: MyInfoFeature.State()) { MyInfoFeature() }
        store.dependencies.authClient.logout = { }

        await store.send(.logoutTapped) { $0.alert = MyInfoFeature.logoutAlert }
        await store.send(.alert(.presented(.confirmLogout))) { $0.alert = nil }
        await store.receive(.logoutSucceeded) {
            $0.didLogout = true
        }
    }
}
