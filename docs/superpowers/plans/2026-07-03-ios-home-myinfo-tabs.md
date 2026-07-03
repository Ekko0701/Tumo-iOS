# iOS 홈·내 정보 탭 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** placeholder 상태인 `홈`·`내 정보` 탭을, 기존 데이터를 조합한 홈 대시보드(자산 요약 + 급상승 종목 + 최근 주문)와 프로필+메뉴 화면(내 정보 조회·로그아웃 포함)으로 채운다.

**Architecture:** 새 feature 모듈 `HomeFeature`·`MyInfoFeature`를 만든다. 홈은 기존 `stockClient`(포트폴리오·랭킹)+`orderClient`(최근 주문)를 조합하고, 급상승 행 탭 시 이미 public인 `StockDetailFeature`를 재사용한다. 내 정보는 `AuthClient`에 새로 추가하는 `fetchMe`·`logout`을 쓰고, 로그아웃은 `didLogout` 플래그 → `MainView(onLoggedOut:)` → `AppFeature.logout` → `route=.auth`로 전달한다. 교차 모듈 소비를 위해 `StockClient`·`OrderClient`를 public으로 승격한다.

**Tech Stack:** Swift 6, SwiftUI, TCA, Tuist. JWT는 `TumoProviderFactory.live.authorizedProvider()`. 테스트는 XCTest + TCA `TestStore`.

## Global Constraints

- **백엔드 엔드포인트**(모두 기존, 신규 백엔드 0):
  - `GET /api/v1/users/me` (JWT) → `{ id: Int64, email: String, nickname: String, cashBalance: Int64 }`
  - `POST /api/v1/auth/logout` (JWT) → 204 No Content (바디 없음)
  - `GET /api/v1/portfolio` (JWT) → `Portfolio` (`stockClient.fetchPortfolio()`)
  - `GET /api/v1/stocks/rankings?market&type&page&size` → `StockPage` (`stockClient.fetchStockRankings(_:_:_:_:)`)
  - `GET /api/v1/orders?page&size` (JWT) → `OrderPage` (`orderClient.history(_:_:)`)
- **색상**: 캐노니컬 `CoreDesignSystem` `Color.tumoUp`(빨강=상승·이익) / `Color.tumoDown`(파랑=하락·손실). private로 tumoUp/tumoDown 재정의 금지. 등락률·손익 모두 적용.
- **랭킹 타입**: 등락률 상위 = `StockRankingType.rising`(전일 대비 급상승). enum: `popular`/`tradeAmount`/`tradeVolume`/`rising`/`falling`. 시장은 `StockMarket.kospi`.
- **Provider API**: `provider.request(_:as:)`(디코딩), `provider.requestData(_:)`(원시 Data). Void 반환 request 없음 → 바디 없는 응답(logout)은 `_ = try await provider.requestData(.logout)`. 인증 필요 API는 `TumoProviderFactory.live.authorizedProvider()`.
- **`Task`**: 바디 없는 요청 `.requestPlain`; JSON 바디 `.requestJSONEncodable(AnyEncodable(dto))`.
- **`StockDetailFeature`는 이미 완전 public** (`State`/`init(stock:)`/`Action` 모두 public). 홈은 랭킹에서 받은 `Stock`을 그대로 `StockDetailFeature.State(stock:)`에 넣는다(추가 조회 불필요).
- **엔티티/DTO는 이미 public**: `Portfolio`, `StockPage`(`.stocks: [Stock]`), `Stock`(`changePrice: Int?`, `changeRate: Decimal?`), `OrderPage`(`.items: [OrderHistoryItem]`), `OrderHistoryItem`(`orderId, stockCode, stockName, orderType: String, quantity, executedPrice, totalAmount, realizedProfit: Int?, executedAt: String`), `AuthUser`(`id: Int64, email, nickname, cashBalance: Int64`).
- **Tuist**: feature 모듈은 main + Tests + Demo 타깃이 항상 생성됨 → 새 모듈에 `Sources/**`·`Tests/Sources/**`·`Demo/Sources/**` 각각 최소 1개 파일 필요.
- **코딩 규칙**: `let` 우선, 값타입/`Sendable`, 기존 Clean Arch(API→DataSource→Repository→Usecase→Client→Assembly) + TCA 컨벤션.
- **시뮬레이터**: `id=45CBB754-7B38-41C2-B381-8EB648D8D344`(없으면 `xcrun simctl list devices available`에서 iPhone 시뮬레이터 UDID 선택; 이하 `<sim>`).
- **브랜치**: `feat/home-myinfo-tabs`(이미 생성, 설계 스펙 커밋됨). 각 태스크 끝에 커밋. 최종 push/PR은 사용자 요청 시.

---

## File Structure

**AuthFeature (fetchMe·logout 슬라이스 확장)**
- Create: `Sources/Data/DTO/AuthUserDTO.swift`
- Modify: `Sources/Data/API/AuthAPI.swift` — `.me`/`.logout` case + `method`/`task`
- Create: `Sources/Data/DataSource/Interface/FetchMeDataSource.swift` + `Impl/FetchMeDataSourceImpl.swift`
- Create: `Sources/Data/DataSource/Interface/LogoutDataSource.swift` + `Impl/LogoutDataSourceImpl.swift`
- Create: `Sources/Data/Repository/Interface/FetchMeRepository.swift` + `Impl/FetchMeRepositoryImpl.swift`
- Create: `Sources/Data/Repository/Interface/LogoutRepository.swift` + `Impl/LogoutRepositoryImpl.swift`
- Create: `Sources/Domain/UseCase/Interface/FetchMeUsecase.swift` + `Impl/FetchMeUsecaseImpl.swift`
- Create: `Sources/Domain/UseCase/Interface/LogoutUsecase.swift` + `Impl/LogoutUsecaseImpl.swift`
- Modify: `Sources/Data/Dependency/AuthClient.swift` — `fetchMe`/`logout` 추가
- Modify: `Sources/Data/Dependency/AuthAssembly.swift` — 배선
- Modify: `Tests/Sources/AuthFeatureTests.swift` — usecase 테스트

> 실제 디렉터리 구조는 기존 AuthFeature를 따른다. 위 Interface/Impl 경로가 기존과 다르면 기존 배치에 맞춘다(예: DataSource가 `Interface/`·`Impl/`로 나뉘어 있음을 로그인 슬라이스에서 확인).

**클라이언트 public 승격**
- Modify: `StockFeature/Sources/Data/Dependency/StockClient.swift`
- Modify: `OrderFeature/Sources/Data/Dependency/OrderClient.swift`

**새 모듈**
- Modify: `Tuist/ProjectDescriptionHelpers/TumoModule.swift`
- Create: `Projects/Features/HomeFeature/Project.swift`, `Sources/HomeFeatureNamespace.swift`, `Sources/Presentation/HomeFeature.swift`, `Sources/Presentation/HomeView.swift`, `Demo/Sources/HomeFeatureDemoApp.swift`, `Tests/Sources/HomeFeatureTests.swift`
- Create: `Projects/Features/MyInfoFeature/Project.swift`, `Sources/MyInfoFeatureNamespace.swift`, `Sources/Presentation/MyInfoFeature.swift`, `Sources/Presentation/MyInfoView.swift`, `Demo/Sources/MyInfoFeatureDemoApp.swift`, `Tests/Sources/MyInfoFeatureTests.swift`
- Modify: `Projects/App/Project.swift` — 두 모듈 의존 추가

**App 통합**
- Modify: `Projects/App/Sources/AppFeature.swift` — `.logout`
- Modify: `Projects/App/Sources/RootView.swift` — `MainView(onLoggedOut:)`
- Modify: `Projects/App/Sources/MainView.swift` — `onLoggedOut` + `.home`/`.my` 연결

---

## Task 1: AuthFeature — fetchMe·logout 데이터 슬라이스 + Usecase 테스트

**Files:**
- Create: `Projects/Features/AuthFeature/Sources/Data/DTO/AuthUserDTO.swift`
- Modify: `Projects/Features/AuthFeature/Sources/Data/API/AuthAPI.swift`
- Create: FetchMe/Logout DataSource(Interface+Impl), Repository(Interface+Impl), Usecase(Interface+Impl) — 경로는 File Structure 참조
- Modify: `Projects/Features/AuthFeature/Tests/Sources/AuthFeatureTests.swift`

**Interfaces:**
- Consumes: `Provider<AuthAPI>`, `AuthUser`, `any AuthTokenRepository`(기존; `delete()`), `TumoProviderFactory.live.authorizedProvider()`.
- Produces: `any FetchMeUsecase { func execute() async throws -> AuthUser }`, `any LogoutUsecase { func execute() async throws }`, `FetchMeRepositoryImpl(fetchMeDataSource:)`, `LogoutRepositoryImpl(logoutDataSource:)`, `FetchMeUsecaseImpl(fetchMeRepository:)`, `LogoutUsecaseImpl(logoutRepository:authTokenRepository:)`.

- [ ] **Step 1: `AuthUserDTO` 생성** (`AuthUserDTO.swift`)
```swift
import Foundation

/// `GET /api/v1/users/me` 응답. `AuthUser` 도메인 엔티티로 매핑된다.
struct AuthUserDTO: Decodable, Sendable, Equatable {
    let id: Int64
    let email: String
    let nickname: String
    let cashBalance: Int64
}
```

- [ ] **Step 2: `AuthAPI`에 `.me`/`.logout` 추가**

case 목록에 추가:
```swift
    case me
    case logout
```
`path` switch에 추가:
```swift
        case .me:
            "/api/v1/users/me"

        case .logout:
            "/api/v1/auth/logout"
```
`method`를 case별로 분기하도록 변경(기존이 전 case `.post`였다면 아래로 교체):
```swift
    var method: HTTPMethod {
        switch self {
        case .login, .signup, .refreshToken, .logout:
            .post
        case .me:
            .get
        }
    }
```
`task` switch에 추가(바디 없음):
```swift
        case .me, .logout:
            .requestPlain
```

- [ ] **Step 3: FetchMe DataSource + Impl** (로그인 슬라이스 미러)
```swift
// Interface/FetchMeDataSource.swift
protocol FetchMeDataSource: Sendable {
    func fetchMe() async throws -> AuthUserDTO
}
```
```swift
// Impl/FetchMeDataSourceImpl.swift
import TumoNetwork

struct FetchMeDataSourceImpl: FetchMeDataSource {
    private let provider: Provider<AuthAPI>
    init(provider: Provider<AuthAPI>) { self.provider = provider }

    func fetchMe() async throws -> AuthUserDTO {
        try await provider.request(.me, as: AuthUserDTO.self)
    }
}
```

- [ ] **Step 4: Logout DataSource + Impl** (바디/응답 없음 → `requestData`)
```swift
// Interface/LogoutDataSource.swift
protocol LogoutDataSource: Sendable {
    func logout() async throws
}
```
```swift
// Impl/LogoutDataSourceImpl.swift
import TumoNetwork

struct LogoutDataSourceImpl: LogoutDataSource {
    private let provider: Provider<AuthAPI>
    init(provider: Provider<AuthAPI>) { self.provider = provider }

    func logout() async throws {
        _ = try await provider.requestData(.logout)
    }
}
```

- [ ] **Step 5: Repository Interface + Impl** (DTO→Entity 매핑)
```swift
// FetchMeRepository.swift
protocol FetchMeRepository: Sendable {
    func fetchMe() async throws -> AuthUser
}
```
```swift
// FetchMeRepositoryImpl.swift
struct FetchMeRepositoryImpl: FetchMeRepository {
    private let fetchMeDataSource: any FetchMeDataSource
    init(fetchMeDataSource: any FetchMeDataSource) { self.fetchMeDataSource = fetchMeDataSource }

    func fetchMe() async throws -> AuthUser {
        let dto = try await fetchMeDataSource.fetchMe()
        return AuthUser(id: dto.id, email: dto.email, nickname: dto.nickname, cashBalance: dto.cashBalance)
    }
}
```
```swift
// LogoutRepository.swift
protocol LogoutRepository: Sendable {
    func logout() async throws
}
```
```swift
// LogoutRepositoryImpl.swift
struct LogoutRepositoryImpl: LogoutRepository {
    private let logoutDataSource: any LogoutDataSource
    init(logoutDataSource: any LogoutDataSource) { self.logoutDataSource = logoutDataSource }

    func logout() async throws {
        try await logoutDataSource.logout()
    }
}
```

- [ ] **Step 6: Usecase Interface + Impl**
```swift
// FetchMeUsecase.swift
protocol FetchMeUsecase: Sendable {
    func execute() async throws -> AuthUser
}
```
```swift
// FetchMeUsecaseImpl.swift
struct FetchMeUsecaseImpl: FetchMeUsecase {
    private let fetchMeRepository: any FetchMeRepository
    init(fetchMeRepository: any FetchMeRepository) { self.fetchMeRepository = fetchMeRepository }

    func execute() async throws -> AuthUser {
        try await fetchMeRepository.fetchMe()
    }
}
```
```swift
// LogoutUsecase.swift
protocol LogoutUsecase: Sendable {
    func execute() async throws
}
```
```swift
// LogoutUsecaseImpl.swift  — 백엔드 실패와 무관하게 로컬 토큰 삭제(로컬 로그아웃 항상 성립)
struct LogoutUsecaseImpl: LogoutUsecase {
    private let logoutRepository: any LogoutRepository
    private let authTokenRepository: any AuthTokenRepository
    init(logoutRepository: any LogoutRepository, authTokenRepository: any AuthTokenRepository) {
        self.logoutRepository = logoutRepository
        self.authTokenRepository = authTokenRepository
    }

    func execute() async throws {
        do {
            try await logoutRepository.logout()
        } catch {
            try? authTokenRepository.delete()
            throw error
        }
        try authTokenRepository.delete()
    }
}
```
> `AuthTokenRepository` 프로토콜의 정확한 메서드 시그니처를 `AuthFeature/.../Repository/.../AuthTokenRepository*.swift`에서 확인할 것(기존 `RefreshSessionUsecaseImpl`이 `authTokenRepository.delete()`, `.load()`를 호출함). `delete() throws`가 확인 대상.

- [ ] **Step 7: 실패 테스트 작성** (`AuthFeatureTests.swift`에 추가; import/스타일은 기존 파일을 따른다)
```swift
@MainActor
final class AuthUserUsecaseTests: XCTestCase {
    private struct StubFetchMeRepository: FetchMeRepository {
        let user: AuthUser
        func fetchMe() async throws -> AuthUser { user }
    }
    private struct StubLogoutRepository: LogoutRepository {
        let error: Error?
        func logout() async throws { if let error { throw error } }
    }
    // AuthTokenRepository 프로토콜에 맞춰 필요한 메서드만 구현(시그니처는 인터페이스 파일 확인).
    private final class SpyAuthTokenRepository: AuthTokenRepository, @unchecked Sendable {
        private(set) var deleteCallCount = 0
        func save(_ authToken: AuthToken) throws {}
        func load() throws -> StoredAuthToken? { nil }
        func delete() throws { deleteCallCount += 1 }
    }

    func test_fetchMe_returnsUser() async throws {
        let user = AuthUser(id: 1, email: "a@b.com", nickname: "테스터", cashBalance: 10_000_000)
        let usecase = FetchMeUsecaseImpl(fetchMeRepository: StubFetchMeRepository(user: user))
        let result = try await usecase.execute()
        XCTAssertEqual(result, user)
    }

    func test_logout_success_deletesToken() async throws {
        let spy = SpyAuthTokenRepository()
        let usecase = LogoutUsecaseImpl(logoutRepository: StubLogoutRepository(error: nil), authTokenRepository: spy)
        try await usecase.execute()
        XCTAssertEqual(spy.deleteCallCount, 1)
    }

    func test_logout_backendFailure_stillDeletesTokenAndRethrows() async {
        struct Boom: Error {}
        let spy = SpyAuthTokenRepository()
        let usecase = LogoutUsecaseImpl(logoutRepository: StubLogoutRepository(error: Boom()), authTokenRepository: spy)
        do {
            try await usecase.execute()
            XCTFail("should rethrow")
        } catch {
            XCTAssertEqual(spy.deleteCallCount, 1)
        }
    }
}
```
> `SpyAuthTokenRepository`의 `save`/`load` 시그니처와 `StoredAuthToken` 타입은 실제 `AuthTokenRepository` 인터페이스에 맞춘다. 프로토콜이 `save(_:)`/`load()`/`delete()`와 다르면 구현을 맞출 것.

- [ ] **Step 8: 테스트 실패 확인** — Run: `cd /Users/kimdongjoo/Desktop/Tumo/Tumo-iOS && tuist generate && xcodebuild test -scheme AuthFeature -destination 'id=<sim>'`. Expected: 컴파일 실패(신규 타입 미정의) 또는 신규 테스트 FAIL.

- [ ] **Step 9: 구현 후 테스트 통과 확인** — Step 1~6 구현 완료 상태에서 Run 동일. Expected: 신규 3 테스트 PASS + 기존 통과. (아직 `AuthClient`/`AuthAssembly` 미배선이므로 컴파일만 되면 됨. Assembly가 신규 usecase를 아직 안 만들어도 무방.)

- [ ] **Step 10: Commit**
```bash
git add Projects/Features/AuthFeature/Sources Projects/Features/AuthFeature/Tests
git commit -m "feat(auth): add fetchMe/logout data slice (API, datasource, repository, usecase) with tests"
```

---

## Task 2: AuthClient·AuthAssembly 배선 (fetchMe·logout 노출)

**Files:**
- Modify: `Projects/Features/AuthFeature/Sources/Data/Dependency/AuthClient.swift`
- Modify: `Projects/Features/AuthFeature/Sources/Data/Dependency/AuthAssembly.swift`

**Interfaces:**
- Consumes: `FetchMeUsecase`, `LogoutUsecase` (Task 1).
- Produces: `AuthClient.fetchMe: @Sendable () async throws -> AuthUser`, `AuthClient.logout: @Sendable () async throws -> Void` (MyInfoFeature가 사용).

- [ ] **Step 1: `AuthClient` struct에 프로퍼티 추가** (`refreshSession` 아래)
```swift
    public var fetchMe: @Sendable () async throws -> AuthUser
    public var logout: @Sendable () async throws -> Void
```

- [ ] **Step 2: `init` 파라미터·대입 추가**

`init(...)` 파라미터 목록 끝에 추가:
```swift
        fetchMe: @escaping @Sendable () async throws -> AuthUser,
        logout: @escaping @Sendable () async throws -> Void
```
본문 끝에 대입:
```swift
        self.fetchMe = fetchMe
        self.logout = logout
```

- [ ] **Step 3: `static func live` 확장**

`live(...)` 파라미터에 추가:
```swift
        fetchMeUsecase: any FetchMeUsecase,
        logoutUsecase: any LogoutUsecase
```
`AuthClient(...)` 생성 인자에 추가:
```swift
            fetchMe: {
                try await fetchMeUsecase.execute()
            },
            logout: {
                try await logoutUsecase.execute()
            }
```

- [ ] **Step 4: `AuthAssembly.live()` 배선**

`live()` 내부에 authorizedProvider 및 신규 그래프 추가(로그인 슬라이스와 동일 스타일):
```swift
        let authorizedProvider: Provider<AuthAPI> = TumoProviderFactory.live.authorizedProvider()

        let fetchMeDataSource = FetchMeDataSourceImpl(provider: authorizedProvider)
        let logoutDataSource = LogoutDataSourceImpl(provider: authorizedProvider)

        let fetchMeRepository = FetchMeRepositoryImpl(fetchMeDataSource: fetchMeDataSource)
        let logoutRepository = LogoutRepositoryImpl(logoutDataSource: logoutDataSource)

        let fetchMeUsecase = FetchMeUsecaseImpl(fetchMeRepository: fetchMeRepository)
        let logoutUsecase = LogoutUsecaseImpl(
            logoutRepository: logoutRepository,
            authTokenRepository: authTokenRepository
        )
```
> `authTokenRepository`는 기존 `live()`에 이미 선언되어 있음(로그인 usecase가 사용). 없으면 기존 선언 위치를 확인해 재사용. `authorizedProvider` 지역 변수가 이미 있으면 중복 선언 금지.

`return AuthClient.live(...)` 호출 인자 끝에 추가:
```swift
            fetchMeUsecase: fetchMeUsecase,
            logoutUsecase: logoutUsecase
```

- [ ] **Step 5: 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme AuthFeature -destination 'id=<sim>' build` 및 `xcodebuild test -scheme AuthFeature -destination 'id=<sim>'`. Expected: BUILD SUCCEEDED, 테스트 통과. (기존 `AuthClient(` 다른 생성 지점이 있으면 grep `AuthClient(`로 찾아 신규 파라미터를 채울 것 — testValue 등.)
```bash
git add Projects/Features/AuthFeature/Sources/Data/Dependency
git commit -m "feat(auth): expose fetchMe/logout on AuthClient and wire AuthAssembly"
```

---

## Task 3: StockClient·OrderClient public 승격

**Files:**
- Modify: `Projects/Features/StockFeature/Sources/Data/Dependency/StockClient.swift`
- Modify: `Projects/Features/OrderFeature/Sources/Data/Dependency/OrderClient.swift`

**Interfaces:**
- Produces: `public struct StockClient`(모든 프로퍼티/`init` public, `DependencyValues.stockClient` public), `public struct OrderClient`(동일). HomeFeature가 `@Dependency(\.stockClient)`/`\.orderClient`로 소비.

- [ ] **Step 1: `StockClient` public화**

`StockClient.swift`에서:
- `struct StockClient: Sendable` → `public struct StockClient: Sendable`
- 모든 저장 프로퍼티 `var X: ...` → `public var X: ...` (fetchStocks, fetchStockRankings, fetchStock, observeRealtimePrices, observeOrderBook, fetchHolding, fetchPortfolio, fetchCandles)
- `init(...)` → `public init(...)`
- `extension DependencyValues { var stockClient: ... }` → 멤버를 `public var stockClient`로

> `static func live(...)`와 `private enum StockClientKey`는 그대로(내부 유지). 외부 모듈은 `@Dependency(\.stockClient)`(public 접근자)로 liveValue를 읽고, 테스트는 `store.dependencies.stockClient.X = ...`(public var setter)로 오버라이드한다.

- [ ] **Step 2: `OrderClient` public화**

`OrderClient.swift`에서:
- `struct OrderClient: Sendable` → `public struct OrderClient: Sendable`
- `var buy` / `var sell` / `var history` → 각각 `public var`
- `init(...)` → `public init(...)`
- `extension DependencyValues { var orderClient: ... }` → `public var orderClient`

> `static func live`, `private enum OrderClientKey`(내부 `testValue` 포함)는 그대로.

- [ ] **Step 3: 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme StockFeature -destination 'id=<sim>' build && xcodebuild -scheme OrderFeature -destination 'id=<sim>' build && xcodebuild test -scheme StockFeature -destination 'id=<sim>' && xcodebuild test -scheme OrderFeature -destination 'id=<sim>'`. Expected: 모두 성공(기존 테스트 그대로 통과).
```bash
git add Projects/Features/StockFeature/Sources/Data/Dependency/StockClient.swift Projects/Features/OrderFeature/Sources/Data/Dependency/OrderClient.swift
git commit -m "refactor(clients): make StockClient and OrderClient public for cross-module reuse"
```

---

## Task 4: 새 모듈 스캐폴딩 + Tuist 등록 (HomeFeature·MyInfoFeature)

**Files:**
- Modify: `Tuist/ProjectDescriptionHelpers/TumoModule.swift`
- Create: `Projects/Features/HomeFeature/{Project.swift, Sources/HomeFeatureNamespace.swift, Demo/Sources/HomeFeatureDemoApp.swift, Tests/Sources/HomeFeatureTests.swift}`
- Create: `Projects/Features/MyInfoFeature/{Project.swift, Sources/MyInfoFeatureNamespace.swift, Demo/Sources/MyInfoFeatureDemoApp.swift, Tests/Sources/MyInfoFeatureTests.swift}`
- Modify: `Projects/App/Project.swift`

**Interfaces:**
- Produces: 빈 채로 빌드되는 `HomeFeature`·`MyInfoFeature` 모듈(다음 태스크가 소스 추가).

- [ ] **Step 1: `TumoModule`에 case 추가**

`case portfolioFeature = "PortfolioFeature"` 아래에 추가:
```swift
    case homeFeature = "HomeFeature"
    case myInfoFeature = "MyInfoFeature"
```
`projectPath` switch에 추가:
```swift
        case .homeFeature:
            "Projects/Features/HomeFeature"
        case .myInfoFeature:
            "Projects/Features/MyInfoFeature"
```
`isFeature`의 `true` case 목록에 `.homeFeature, .myInfoFeature` 추가:
```swift
        case .authFeature, .stockFeature, .orderFeature, .portfolioFeature, .homeFeature, .myInfoFeature:
            true
```

- [ ] **Step 2: HomeFeature `Project.swift`**
```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .homeFeature,
    dependencies: [
        .module(.stockFeature),
        .module(.orderFeature),
        .module(.coreDesignSystem)
    ]
)
```

- [ ] **Step 3: HomeFeature 최소 Sources/Demo/Tests**
```swift
// Sources/HomeFeatureNamespace.swift
/// HomeFeature 모듈 네임스페이스 마커. (실제 화면은 Presentation/에 구현)
enum HomeFeatureNamespace {}
```
```swift
// Demo/Sources/HomeFeatureDemoApp.swift
import SwiftUI

@main
struct HomeFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            Text("HomeFeature Demo")
        }
    }
}
```
```swift
// Tests/Sources/HomeFeatureTests.swift
import XCTest
@testable import HomeFeature

final class HomeFeaturePlaceholderTests: XCTestCase {
    func test_placeholder() { XCTAssertTrue(true) }
}
```

- [ ] **Step 4: MyInfoFeature `Project.swift`**
```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .myInfoFeature,
    dependencies: [
        .module(.authFeature),
        .module(.orderFeature),
        .module(.stockFeature),
        .module(.coreDesignSystem)
    ]
)
```

- [ ] **Step 5: MyInfoFeature 최소 Sources/Demo/Tests**
```swift
// Sources/MyInfoFeatureNamespace.swift
/// MyInfoFeature 모듈 네임스페이스 마커.
enum MyInfoFeatureNamespace {}
```
```swift
// Demo/Sources/MyInfoFeatureDemoApp.swift
import SwiftUI

@main
struct MyInfoFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            Text("MyInfoFeature Demo")
        }
    }
}
```
```swift
// Tests/Sources/MyInfoFeatureTests.swift
import XCTest
@testable import MyInfoFeature

final class MyInfoFeaturePlaceholderTests: XCTestCase {
    func test_placeholder() { XCTAssertTrue(true) }
}
```

- [ ] **Step 6: `App/Project.swift`에 의존 추가**

`dependencies` 배열의 `.module(.portfolioFeature)` 아래에 추가:
```swift
        .module(.homeFeature),
        .module(.myInfoFeature)
```

- [ ] **Step 7: 생성·빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme HomeFeature -destination 'id=<sim>' build && xcodebuild -scheme MyInfoFeature -destination 'id=<sim>' build && xcodebuild -scheme Tumo -destination 'id=<sim>' build`. Expected: 모두 BUILD SUCCEEDED.
```bash
git add Tuist/ProjectDescriptionHelpers/TumoModule.swift Projects/Features/HomeFeature Projects/Features/MyInfoFeature Projects/App/Project.swift
git commit -m "chore(modules): scaffold HomeFeature and MyInfoFeature modules"
```

---

## Task 5: HomeFeature 리듀서 + 테스트

**Files:**
- Create: `Projects/Features/HomeFeature/Sources/Presentation/HomeFeature.swift`
- Modify: `Projects/Features/HomeFeature/Tests/Sources/HomeFeatureTests.swift`

**Interfaces:**
- Consumes: `StockClient.fetchPortfolio`/`fetchStockRankings`, `OrderClient.history`, `Portfolio`, `Stock`, `StockPage`, `OrderPage`, `OrderHistoryItem`, `StockDetailFeature`.
- Produces: `HomeFeature` with `State(portfolio: Portfolio?, topMovers: [Stock], recentOrders: [OrderHistoryItem], isLoading, errorMessage, @Presents stockDetail)`; Actions `onAppear`/`refresh`/`dataLoaded(Portfolio,[Stock],[OrderHistoryItem])`/`loadFailed`/`stockTapped(Stock)`/`stockDetail(...)`.

- [ ] **Step 1: 실패 테스트 작성** (`HomeFeatureTests.swift` 전체 교체)
```swift
import ComposableArchitecture
import OrderFeature
import StockFeature
import XCTest
@testable import HomeFeature

@MainActor
final class HomeFeatureTests: XCTestCase {
    private func portfolio() -> Portfolio {
        Portfolio(cashBalance: 9_250_000, totalStockValue: 750_000, totalAsset: 10_000_000,
                  profitAmount: 50_000, profitRate: 0.5,
                  holdings: [StockHolding(stockCode: "005930", stockName: "삼성전자", quantity: 10,
                                          averagePrice: 70_000, currentPrice: 75_000, evaluationAmount: 750_000,
                                          profitAmount: 50_000, profitRate: 7.1)])
    }
    private func mover(_ code: String) -> Stock {
        Stock(stockCode: code, stockName: "종목\(code)", market: "KOSPI", currentPrice: 75_000,
              changePrice: 2_000, changeRate: Decimal(string: "2.74"), tradeVolume: 1, tradeAmount: 1,
              priceChangedAt: "2026-07-03T10:00:00")
    }
    private func order(_ id: Int) -> OrderHistoryItem {
        OrderHistoryItem(orderId: id, stockCode: "005930", stockName: "삼성전자", orderType: "BUY",
                         quantity: 4, executedPrice: 80_000, totalAmount: 320_000, realizedProfit: nil,
                         executedAt: "2026-07-03T10:00:00")
    }

    func test_onAppear_loadsDashboard() async {
        let p = portfolio(); let movers = [mover("005930"), mover("000660")]; let orders = [order(1), order(2)]
        let store = TestStore(initialState: HomeFeature.State()) { HomeFeature() }
        store.dependencies.stockClient.fetchPortfolio = { p }
        store.dependencies.stockClient.fetchStockRankings = { _, _, _, _ in
            StockPage(stocks: movers, page: 0, hasNext: false)
        }
        store.dependencies.orderClient.history = { _, _ in OrderPage(items: orders, page: 0, hasNext: false) }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.dataLoaded(p, movers, orders)) {
            $0.isLoading = false
            $0.portfolio = p
            $0.topMovers = movers
            $0.recentOrders = orders
        }
    }

    func test_onAppear_failureSetsError() async {
        struct Boom: Error {}
        let store = TestStore(initialState: HomeFeature.State()) { HomeFeature() }
        store.dependencies.stockClient.fetchPortfolio = { throw Boom() }
        store.dependencies.stockClient.fetchStockRankings = { _, _, _, _ in StockPage(stocks: [], page: 0, hasNext: false) }
        store.dependencies.orderClient.history = { _, _ in OrderPage(items: [], page: 0, hasNext: false) }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "홈 정보를 불러오지 못했습니다."
        }
    }

    func test_stockTapped_presentsDetail() async {
        let stock = mover("005930")
        let store = TestStore(initialState: HomeFeature.State()) { HomeFeature() }
        await store.send(.stockTapped(stock)) {
            $0.stockDetail = StockDetailFeature.State(stock: stock)
        }
    }
}
```

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -scheme HomeFeature -destination 'id=<sim>'`. Expected: 컴파일 실패(HomeFeature 미구현).

- [ ] **Step 3: `HomeFeature` 구현** (`HomeFeature.swift`)
```swift
import ComposableArchitecture
import OrderFeature
import StockFeature

@Reducer
public struct HomeFeature {
    @Dependency(\.stockClient) private var stockClient
    @Dependency(\.orderClient) private var orderClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var portfolio: Portfolio?
        public var topMovers: [Stock]
        public var recentOrders: [OrderHistoryItem]
        public var isLoading: Bool
        public var errorMessage: String?
        @Presents public var stockDetail: StockDetailFeature.State?

        public init(portfolio: Portfolio? = nil, topMovers: [Stock] = [], recentOrders: [OrderHistoryItem] = [],
                    isLoading: Bool = false, errorMessage: String? = nil,
                    stockDetail: StockDetailFeature.State? = nil) {
            self.portfolio = portfolio
            self.topMovers = topMovers
            self.recentOrders = recentOrders
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.stockDetail = stockDetail
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case dataLoaded(Portfolio, [Stock], [OrderHistoryItem])
        case loadFailed
        case stockTapped(Stock)
        case stockDetail(PresentationAction<StockDetailFeature.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.portfolio == nil, !state.isLoading else { return .none }
                return load(&state)

            case .refresh:
                return load(&state)

            case let .dataLoaded(portfolio, movers, orders):
                state.isLoading = false
                state.errorMessage = nil
                state.portfolio = portfolio
                state.topMovers = movers
                state.recentOrders = orders
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "홈 정보를 불러오지 못했습니다."
                return .none

            case let .stockTapped(stock):
                state.stockDetail = StockDetailFeature.State(stock: stock)
                return .none

            case .stockDetail:
                return .none
            }
        }
        .ifLet(\.$stockDetail, action: \.stockDetail) {
            StockDetailFeature()
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let stockClient = stockClient
        let orderClient = orderClient
        return .run { send in
            do {
                async let portfolio = stockClient.fetchPortfolio()
                async let movers = stockClient.fetchStockRankings(.kospi, .rising, 0, 5)
                async let orders = orderClient.history(0, 5)
                let (p, m, o) = try await (portfolio, movers, orders)
                await send(.dataLoaded(p, m.stocks, o.items))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
```

- [ ] **Step 4: 테스트 통과 확인** — Run: `xcodebuild test -scheme HomeFeature -destination 'id=<sim>'`. Expected: 신규 3개 PASS (placeholder 테스트는 제거됨).

- [ ] **Step 5: Commit**
```bash
git add Projects/Features/HomeFeature/Sources/Presentation/HomeFeature.swift Projects/Features/HomeFeature/Tests/Sources/HomeFeatureTests.swift
git commit -m "feat(home): add HomeFeature reducer composing portfolio, movers, recent orders"
```

---

## Task 6: HomeView

**Files:**
- Create: `Projects/Features/HomeFeature/Sources/Presentation/HomeView.swift`
- Modify: `Projects/Features/HomeFeature/Demo/Sources/HomeFeatureDemoApp.swift`

**Interfaces:**
- Consumes: `HomeFeature` (Task 5), `StockDetailView`(StockFeature).

- [ ] **Step 1: `HomeView` 구현**

`PortfolioView`의 구조/토큰/상태분기를 미러링한다. `public struct HomeView: View`, 기본 store 인자(`Store(initialState: HomeFeature.State()) { HomeFeature() }`), `@Bindable var store`. `import ComposableArchitecture, CoreDesignSystem, StockFeature, OrderFeature, Foundation, SwiftUI`.

구성(위→아래, `ScrollView` + `.refreshable { store.send(.refresh) }`, `.task { store.send(.onAppear) }`):
1. **헤더**: `Text("홈")` 26pt bold `Color.tumoInk` + 부제 "나의 투자 현황" 14pt `Color.tumoMuted` (PortfolioHeader 스타일).
2. **자산 요약 카드**(portfolio 있을 때): 총자산 `portfolio.totalAsset.formatted() + "원"` 28pt bold; 평가손익 `profitAmount`원 + `(±profitRate%)` — `profitAmount >= 0 ? Color.tumoUp : Color.tumoDown`; 보유현금 `cashBalance`. `PortfolioSummaryCard`와 동일 톤(RoundedRectangle 12, `Color.tumoSurfaceStrong` 배경). PortfolioSummaryCard는 internal이라 재사용 불가 → HomeFeature 내부에 동일 스타일 `HomeSummaryCard` 컴포넌트로 작성.
3. **"급상승" 섹션**: 섹션 타이틀 "급상승" 18pt semibold + `ForEach(store.topMovers, id: \.stockCode)` 행 Button → `store.send(.stockTapped(stock))`. 행 라벨: 종목명(semibold, tumoInk)·종목코드(tumoMuted) / 우측 현재가 `currentPrice.formatted()`원 + 등락률 `changeRate` — 색 `Color.tumoUp`(>=0)/`Color.tumoDown`(<0), `changeRate == nil`이면 "—". 등락률 문자열은 `String(format: "%+.2f%%", (rate as NSDecimalNumber).doubleValue)` 형태. 행 사이 `Color.tumoHairlineSoft` 1px.
4. **"최근 주문" 섹션**: 타이틀 "최근 주문" + `ForEach(store.recentOrders)` 비탭 행: 종목명 · 매수/매도 뱃지(`orderType == "BUY" ? "매수"(tumoUp) : "매도"(tumoDown)`) · `"\(quantity)주"` · `executedPrice.formatted()`원. 빈 배열이면 "최근 주문이 없습니다" 문구.
5. **상태 분기**: 초기 로딩(`isLoading && portfolio == nil`) → 스켈레톤(PortfolioSkeletonRow 톤의 자체 스켈레톤 몇 줄); 에러(`errorMessage`) → 메시지 + "다시 시도" 버튼(`.refresh`), PortfolioErrorState 스타일; 정상 → 카드+두 섹션.
6. **네비게이션**: `.navigationDestination(item: $store.scope(state: \.stockDetail, action: \.stockDetail)) { StockDetailView(store: $0) }`.
7. 배경 `Color.tumoCanvas`, `.navigationBarTitleDisplayMode(.inline)` + `.toolbar(.hidden, for: .navigationBar)`(PortfolioView와 동일).
8. `#Preview`로 정상/빈 상태(선택).

> 색상/타이포는 캐노니컬 `CoreDesignSystem` 토큰(`tumoUp`/`tumoDown`/`tumoInk`/`tumoBody`/`tumoMuted`/`tumoHairlineSoft`/`tumoSurfaceStrong`/`tumoCanvas`)만 사용. private tumoUp/tumoDown 재정의 금지. 뷰는 자동 테스트 대상 아님(컴파일/프리뷰로 확인).

- [ ] **Step 2: Demo 앱을 `HomeView()`로 갱신**
```swift
import HomeFeature
import SwiftUI

@main
struct HomeFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
    }
}
```

- [ ] **Step 3: 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme HomeFeature -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/Features/HomeFeature/Sources/Presentation/HomeView.swift Projects/Features/HomeFeature/Demo/Sources/HomeFeatureDemoApp.swift
git commit -m "feat(home): add HomeView dashboard (asset card, top movers, recent orders)"
```

---

## Task 7: MyInfoFeature 리듀서 + 테스트

**Files:**
- Create: `Projects/Features/MyInfoFeature/Sources/Presentation/MyInfoFeature.swift`
- Modify: `Projects/Features/MyInfoFeature/Tests/Sources/MyInfoFeatureTests.swift`

**Interfaces:**
- Consumes: `AuthClient.fetchMe`/`logout` (Task 2), `AuthUser`.
- Produces: `MyInfoFeature` with `State(profile: AuthUser?, isLoading, errorMessage, didLogout, @Presents alert)`; Actions `onAppear`/`profileLoaded(AuthUser)`/`loadFailed`/`logoutTapped`/`alert(...)`/`logoutSucceeded`; `static let logoutAlert`.

- [ ] **Step 1: 실패 테스트 작성** (`MyInfoFeatureTests.swift` 전체 교체)
```swift
import AuthFeature
import ComposableArchitecture
import XCTest
@testable import MyInfoFeature

@MainActor
final class MyInfoFeatureTests: XCTestCase {
    private let user = AuthUser(id: 1, email: "a@b.com", nickname: "테스터", cashBalance: 10_000_000)

    func test_onAppear_loadsProfile() async {
        let store = TestStore(initialState: MyInfoFeature.State()) { MyInfoFeature() }
        store.dependencies.authClient.fetchMe = { self.user }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.profileLoaded(user)) {
            $0.isLoading = false
            $0.profile = self.user
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
        await store.send(.alert(.presented(.confirmLogout)))
        await store.receive(.logoutSucceeded) {
            $0.alert = nil
            $0.didLogout = true
        }
    }
}
```
> `.alert(.presented(...))` 후 TCA가 `alert`을 nil로 만든다. `logoutSucceeded` 기대 상태(`$0.alert = nil`)가 실제와 다르면 실패 메시지대로 조정.

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -scheme MyInfoFeature -destination 'id=<sim>'`. Expected: 컴파일 실패.

- [ ] **Step 3: `MyInfoFeature` 구현** (`MyInfoFeature.swift`)
```swift
import AuthFeature
import ComposableArchitecture

@Reducer
public struct MyInfoFeature {
    @Dependency(\.authClient) private var authClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var profile: AuthUser?
        public var isLoading: Bool
        public var errorMessage: String?
        public var didLogout: Bool
        @Presents public var alert: AlertState<Action.Alert>?

        public init(profile: AuthUser? = nil, isLoading: Bool = false, errorMessage: String? = nil,
                    didLogout: Bool = false, alert: AlertState<Action.Alert>? = nil) {
            self.profile = profile
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.didLogout = didLogout
            self.alert = alert
        }
    }

    public enum Action: Equatable {
        case onAppear
        case profileLoaded(AuthUser)
        case loadFailed
        case logoutTapped
        case logoutSucceeded
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case confirmLogout
        }
    }

    public static let logoutAlert = AlertState<Action.Alert> {
        TextState("로그아웃")
    } actions: {
        ButtonState(role: .destructive, action: .confirmLogout) { TextState("로그아웃") }
        ButtonState(role: .cancel) { TextState("취소") }
    } message: {
        TextState("정말 로그아웃하시겠어요?")
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.profile == nil, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let authClient = authClient
                return .run { send in
                    do {
                        let user = try await authClient.fetchMe()
                        await send(.profileLoaded(user))
                    } catch {
                        await send(.loadFailed)
                    }
                }

            case let .profileLoaded(user):
                state.isLoading = false
                state.errorMessage = nil
                state.profile = user
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "내 정보를 불러오지 못했습니다."
                return .none

            case .logoutTapped:
                state.alert = Self.logoutAlert
                return .none

            case .alert(.presented(.confirmLogout)):
                let authClient = authClient
                return .run { send in
                    // 백엔드 실패와 무관하게 로컬 토큰은 삭제됨 → 항상 로그아웃 처리
                    try? await authClient.logout()
                    await send(.logoutSucceeded)
                }

            case .alert:
                return .none

            case .logoutSucceeded:
                state.didLogout = true
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
```

- [ ] **Step 4: 테스트 통과 확인** — Run: `xcodebuild test -scheme MyInfoFeature -destination 'id=<sim>'`. Expected: 신규 3개 PASS. (`test_logout_confirmSetsDidLogout`의 상태 기대가 실제와 다르면 실패 메시지대로 `$0.alert` 기대를 조정.)

- [ ] **Step 5: Commit**
```bash
git add Projects/Features/MyInfoFeature/Sources/Presentation/MyInfoFeature.swift Projects/Features/MyInfoFeature/Tests/Sources/MyInfoFeatureTests.swift
git commit -m "feat(myinfo): add MyInfoFeature reducer (profile fetch, logout confirm)"
```

---

## Task 8: MyInfoView

**Files:**
- Create: `Projects/Features/MyInfoFeature/Sources/Presentation/MyInfoView.swift`
- Modify: `Projects/Features/MyInfoFeature/Demo/Sources/MyInfoFeatureDemoApp.swift`

**Interfaces:**
- Consumes: `MyInfoFeature` (Task 7), `OrderHistoryView`(OrderFeature), `PortfolioView`(StockFeature).
- Produces: `public struct MyInfoView(onLoggedOut: @escaping () -> Void, store: StoreOf<MyInfoFeature> = 기본)`.

- [ ] **Step 1: `MyInfoView` 구현**

`import AuthFeature, ComposableArchitecture, CoreDesignSystem, OrderFeature, StockFeature, SwiftUI`. `public struct MyInfoView: View`, 프로퍼티 `let onLoggedOut: () -> Void`, `@Bindable var store`. `public init(onLoggedOut: @escaping () -> Void, store: StoreOf<MyInfoFeature> = Store(initialState: .init()) { MyInfoFeature() })`.

구성(`ScrollView`; PortfolioView 톤 유지, 배경 `Color.tumoCanvas`):
1. **프로필 헤더 카드**: 닉네임 `profile?.nickname` 22pt semibold `tumoInk`; 이메일 `profile?.email` 14pt `tumoMuted`; "보유 현금" 라벨 + `profile?.cashBalance.formatted()`원 16pt semibold. RoundedRectangle 12 `tumoSurfaceStrong` 배경. profile nil 로딩 시 상단 ProgressView, `errorMessage` 시 메시지 텍스트(최소).
2. **메뉴 리스트**(각 행 hairline 구분): 
   - "주문 내역" → `NavigationLink { OrderHistoryView() } label: { MenuRow(title: "주문 내역", systemImage: "arrow.left.arrow.right") }`
   - "포트폴리오" → `NavigationLink { PortfolioView() } label: { MenuRow(title: "포트폴리오", systemImage: "wallet.pass") }`
   - "앱 정보" → 비네비 행, 우측 버전 `Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"`
   - "로그아웃" → Button `{ store.send(.logoutTapped) }`, 텍스트 `Color.tumoDown`(destructive 톤).
3. `.alert($store.scope(state: \.alert, action: \.alert))`
4. `.task { store.send(.onAppear) }`
5. `.onChange(of: store.didLogout) { _, newValue in if newValue { onLoggedOut() } }`
6. `.navigationBarTitleDisplayMode(.inline)`.

> `MenuRow`는 이 파일 내부 컴포넌트(제목 + SF Symbol + chevron). NavigationLink 대상 뷰는 자체 store를 생성하므로 추가 배선 불필요. 뷰는 자동 테스트 대상 아님.

- [ ] **Step 2: Demo 앱을 `MyInfoView`로 갱신**
```swift
import MyInfoFeature
import SwiftUI

@main
struct MyInfoFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MyInfoView(onLoggedOut: {})
            }
        }
    }
}
```

- [ ] **Step 3: 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme MyInfoFeature -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/Features/MyInfoFeature/Sources/Presentation/MyInfoView.swift Projects/Features/MyInfoFeature/Demo/Sources/MyInfoFeatureDemoApp.swift
git commit -m "feat(myinfo): add MyInfoView (profile header, menu, logout)"
```

---

## Task 9: App 통합 — 로그아웃 라우팅 + 탭 연결

**Files:**
- Modify: `Projects/App/Sources/AppFeature.swift`
- Modify: `Projects/App/Sources/RootView.swift`
- Modify: `Projects/App/Sources/MainView.swift`

**Interfaces:**
- Consumes: `HomeView`(HomeFeature), `MyInfoView`(MyInfoFeature).
- Produces: `AppFeature.Action.logout`; `MainView(onLoggedOut:)`.

- [ ] **Step 1: `AppFeature`에 `.logout` 추가**

`Action`에 추가:
```swift
        case logout
```
`Reduce`의 switch에 추가(`.auth` 처리 위):
```swift
            case .logout:
                state.route = .auth
                state.auth = AuthFeature.State()
                return .none
```

- [ ] **Step 2: `RootView`에서 MainView에 클로저 전달**

`case .main:`을 교체:
```swift
            case .main:
                MainView(onLoggedOut: { store.send(.logout) })
```

- [ ] **Step 3: `MainView` — onLoggedOut + 탭 연결**

파일 상단 import 추가:
```swift
import HomeFeature
import MyInfoFeature
```
`MainView`에 프로퍼티 추가(구조체 최상단, `@State` 위):
```swift
    let onLoggedOut: () -> Void
```
`MainTabContentView`에 `onLoggedOut` 전달이 필요하므로 시그니처 확장:
```swift
private struct MainTabContentView: View {
    let tab: MainTab
    let onLoggedOut: () -> Void
    // ...
}
```
`MainView.body`의 `MainTabContentView(tab: tab)` → `MainTabContentView(tab: tab, onLoggedOut: onLoggedOut)`.
`MainTabContentView`의 switch에서 `.home, .my` placeholder 분기를 아래로 교체:
```swift
        case .home:
            HomeView()

        case .my:
            MyInfoView(onLoggedOut: onLoggedOut)
```
(placeholder `private var placeholder` 및 `private extension Color`가 더 이상 쓰이지 않으면 제거.)
`#Preview` 교체:
```swift
#Preview {
    MainView(onLoggedOut: {})
}
```

- [ ] **Step 4: 앱 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme Tumo -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/App/Sources/AppFeature.swift Projects/App/Sources/RootView.swift Projects/App/Sources/MainView.swift
git commit -m "feat(app): wire Home/MyInfo tabs and logout routing"
```

---

## Task 10: 전체 검증

- [ ] **Step 1: 전체 테스트/빌드** — Run:
```
xcodebuild test -scheme AuthFeature   -destination 'id=<sim>'
xcodebuild test -scheme HomeFeature   -destination 'id=<sim>'
xcodebuild test -scheme MyInfoFeature -destination 'id=<sim>'
xcodebuild test -scheme StockFeature  -destination 'id=<sim>'
xcodebuild test -scheme OrderFeature  -destination 'id=<sim>'
xcodebuild -scheme Tumo -destination 'id=<sim>' build
```
Expected: 모든 테스트 통과 + 앱 BUILD SUCCEEDED.

- [ ] **Step 2: 수동 시나리오** (로그인 상태):
  - 홈 탭: 자산 요약 카드 · 급상승 상위 5 · 최근 주문 표시 / 당겨서 새로고침 / 급상승 행 탭 → 종목 상세 이동(매수/매도 가능) / 로드 실패 시 에러+재시도
  - 내 정보 탭: 닉네임·이메일·보유현금 표시 / "주문 내역"·"포트폴리오" 진입 / "앱 정보" 버전 표시 / "로그아웃" → 확인 alert → 확인 시 로그인 화면으로 이동(재실행해도 로그인 유지 안 됨 = 토큰 삭제 확인)

- [ ] **Step 3: 최종 커밋/푸시** (사용자 요청 시) — 브랜치 `feat/home-myinfo-tabs` 푸시 후 PR.

---

## Self-Review (작성자 점검 결과)

- **스펙 커버리지**: AuthFeature fetchMe·logout=Task 1·2 / 클라이언트 public화=Task 3 / 모듈 생성=Task 4 / 홈 리듀서·뷰=Task 5·6 / 내정보 리듀서·뷰=Task 7·8 / App 로그아웃 라우팅·탭 연결=Task 9 / 검증=Task 10. 스펙의 모든 섹션에 대응 태스크 존재.
- **스펙 대비 조정**: (1) `StockDetailFeature`는 이미 public → 노출 태스크 불필요(스펙 오픈리스크 해소). (2) 내정보 메뉴 네비게이션은 리듀서 `destination` 상태 대신 **SwiftUI `NavigationLink`**로 단순화(대상 뷰가 자체 store를 갖고 되돌아오는 비즈니스 로직이 없어 YAGNI). 리듀서는 프로필 로드+로그아웃만 담당. (3) 홈 랭킹은 `.rising`(급상승) 사용(스펙에서 정정됨).
- **타입 일관성**: `AuthClient.fetchMe/logout`(Task 2)↔사용(Task 7); `StockClient.fetchPortfolio/fetchStockRankings`·`OrderClient.history` public(Task 3)↔사용(Task 5); `HomeFeature.Action.dataLoaded(Portfolio,[Stock],[OrderHistoryItem])` 정의(5)↔테스트(5) 일치; `StockPage.stocks`/`OrderPage.items`/`StockRankingType.rising`/`StockMarket.kospi` 실제 심볼과 일치; `StockDetailFeature.State(stock:)` public init 사용.
- **구현자 확인 필요(메모)**: ① `AuthTokenRepository` 프로토콜 시그니처(save/load/delete)와 `StoredAuthToken` 타입 — 실제 인터페이스에 맞춰 mock 조정. ② `AuthClient(`/`StockClient(`/`OrderClient(` 다른 생성 지점(testValue 등) 있으면 신규 파라미터/public 반영. ③ `MyInfoFeatureTests`의 alert 상태 기대는 TCA 버전 동작에 맞춰 실패 메시지대로 정렬. ④ 시뮬레이터 UDID.
