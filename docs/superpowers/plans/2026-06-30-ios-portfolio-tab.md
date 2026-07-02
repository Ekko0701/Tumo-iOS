# iOS 포트폴리오 탭 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** '포트폴리오' 탭에 보유 요약(총자산·평가손익·현금)과 보유 종목 목록을 스냅샷+당겨서 새로고침으로 표시하고, 행 탭 시 종목 상세로 이동한다.

**Architecture:** 포트폴리오 탭을 `StockFeature`에 구현한다(포트폴리오 API와 StockDetail이 이미 여기 있어 엔드포인트 중복·교차 모듈 의존이 없고 상세 이동이 같은 모듈 내 push). 기존 `StockDataSource.fetchPortfolio()`(이미 존재)를 재사용하고, `PortfolioResponseDTO`를 확장해 `Portfolio` 엔티티로 매핑한다. `StockView → StockDetail`의 `@Presents`/`.navigationDestination` 네비게이션 패턴을 그대로 미러링한다.

**Tech Stack:** Swift 6, SwiftUI, TCA, Tuist. JWT는 `TumoProviderFactory.authorizedProvider`(기존 PortfolioAPI 경로). 테스트는 XCTest + TCA `TestStore`.

## Global Constraints

- 백엔드 `GET /api/v1/portfolio`(JWT) 응답: `cashBalance, totalStockValue, totalAsset, profitAmount, profitRate, holdings[]{stockCode, stockName, quantity, averagePrice, currentPrice, evaluationAmount, profitAmount, profitRate}` (금액 정수, 비율 Double).
- **색상**: 캐노니컬 CoreDesignSystem `Color.tumoUp`(빨강=이익) / `Color.tumoDown`(파랑=손실). private로 tumoUp/tumoDown 재정의 금지.
- 데이터: 스냅샷 조회 + 당겨서 새로고침(실시간 SSE 아님).
- 코딩 규칙: `let` 우선, 값타입/`Sendable`, 기존 Clean Arch(API→DataSource→Repository→Usecase→Client) + TCA 컨벤션.
- `PortfolioResponseDTO` 확장이 기존 `fetchHolding`(holdings 파싱)에 영향 없어야 함.
- baseURL `http://localhost:8080`(기존 패턴 유지).

---

## File Structure

- `StockFeature/Sources/Domain/Entity/Portfolio.swift` — 생성: `Portfolio` 엔티티
- `StockFeature/Sources/Data/DTO/PortfolioResponseDTO.swift` — 수정: 현금/총자산/총평가/총손익 필드 추가
- `StockFeature/Sources/Domain/Repository/Interface/StockRepository.swift` — 수정: `fetchPortfolio()` 추가
- `StockFeature/Sources/Data/Repository/Impl/StockRepositoryImpl.swift` — 수정: `fetchPortfolio()` 구현 + `toPortfolio()` 매핑
- `StockFeature/Sources/Domain/UseCase/Interface/FetchPortfolioUsecase.swift` + `Impl/FetchPortfolioUsecaseImpl.swift` — 생성
- `StockFeature/Sources/Data/Dependency/StockClient.swift` — 수정: `fetchPortfolio` 클로저 추가
- `StockFeature/Sources/Data/Dependency/StockAssembly.swift` — 수정: 배선
- `StockFeature/Sources/Presentation/Portfolio/PortfolioFeature.swift` + `PortfolioView.swift` — 생성
- `StockFeature/Tests/Sources/StockFeatureTests.swift` — 수정: PortfolioFeature 테스트 추가
- `App/Sources/MainView.swift` — 수정: `.portfolio` 탭 → `PortfolioView()`

---

## Task 1: Portfolio 엔티티 + DTO 확장 + Repository.fetchPortfolio

**Files:**
- Create: `Projects/Features/StockFeature/Sources/Domain/Entity/Portfolio.swift`
- Modify: `Projects/Features/StockFeature/Sources/Data/DTO/PortfolioResponseDTO.swift`
- Modify: `Projects/Features/StockFeature/Sources/Domain/Repository/Interface/StockRepository.swift`
- Modify: `Projects/Features/StockFeature/Sources/Data/Repository/Impl/StockRepositoryImpl.swift`

**Interfaces:**
- Produces: `Portfolio(cashBalance:Int, totalStockValue:Int, totalAsset:Int, profitAmount:Int, profitRate:Double, holdings:[StockHolding])`; `StockRepository.fetchPortfolio() async throws -> Portfolio`.
- Consumes: existing `StockHolding`, existing `StockDataSource.fetchPortfolio() -> PortfolioResponseDTO`.

- [ ] **Step 1: `Portfolio` 엔티티 생성** (`Portfolio.swift`)
```swift
import Foundation

/// 사용자의 포트폴리오 스냅샷(포트폴리오 탭에 표시).
public struct Portfolio: Equatable, Sendable {
    /// 현금 잔고.
    public let cashBalance: Int
    /// 보유 주식 평가 금액 합계.
    public let totalStockValue: Int
    /// 총 자산(현금 + 보유 주식 평가액).
    public let totalAsset: Int
    /// 전체 평가손익 금액.
    public let profitAmount: Int
    /// 전체 수익률(%).
    public let profitRate: Double
    /// 보유 종목 목록.
    public let holdings: [StockHolding]

    public init(
        cashBalance: Int,
        totalStockValue: Int,
        totalAsset: Int,
        profitAmount: Int,
        profitRate: Double,
        holdings: [StockHolding]
    ) {
        self.cashBalance = cashBalance
        self.totalStockValue = totalStockValue
        self.totalAsset = totalAsset
        self.profitAmount = profitAmount
        self.profitRate = profitRate
        self.holdings = holdings
    }
}
```

- [ ] **Step 2: `PortfolioResponseDTO` 확장**

기존 `holdings`는 유지하고 상단 요약 필드를 추가한다 (전체 파일 교체):
```swift
import Foundation

/// `GET /api/v1/portfolio` 응답.
struct PortfolioResponseDTO: Decodable, Sendable, Equatable {
    /// 단일 보유 종목.
    struct PortfolioHoldingDTO: Decodable, Sendable, Equatable {
        let stockCode: String
        let stockName: String
        let quantity: Int
        let averagePrice: Int
        let currentPrice: Int
        let evaluationAmount: Int
        let profitAmount: Int
        let profitRate: Double
    }

    let cashBalance: Int
    let totalStockValue: Int
    let totalAsset: Int
    let profitAmount: Int
    let profitRate: Double
    let holdings: [PortfolioHoldingDTO]
}
```
> 주의: `fetchHolding`은 `holdings`만 쓰므로 영향 없음. 추가 필드는 백엔드가 항상 반환하므로 비-optional로 둔다.

- [ ] **Step 3: `StockRepository`에 `fetchPortfolio()` 추가**

`fetchHolding(...)` 선언 아래에 추가:
```swift
    /// 사용자의 포트폴리오 스냅샷을 조회한다.
    func fetchPortfolio() async throws -> Portfolio
```

- [ ] **Step 4: `StockRepositoryImpl`에 구현 + 매핑 추가**

`fetchHolding(...)` 아래에 메서드 추가:
```swift
    func fetchPortfolio() async throws -> Portfolio {
        let responseDTO = try await stockDataSource.fetchPortfolio()
        return responseDTO.toPortfolio()
    }
```
그리고 기존 `private extension PortfolioResponseDTO.PortfolioHoldingDTO { func toEntity() ... }` 아래에 매핑 추가(기존 holding 매핑 재사용):
```swift
private extension PortfolioResponseDTO {
    func toPortfolio() -> Portfolio {
        Portfolio(
            cashBalance: cashBalance,
            totalStockValue: totalStockValue,
            totalAsset: totalAsset,
            profitAmount: profitAmount,
            profitRate: profitRate,
            holdings: holdings.map { $0.toEntity() }
        )
    }
}
```

- [ ] **Step 5: 빌드 확인 + Commit**

Run: `cd /Users/kimdongjoo/Desktop/Tumo/Tumo-iOS && tuist generate && xcodebuild -scheme StockFeature -destination 'id=45CBB754-7B38-41C2-B381-8EB648D8D344' build` (iPhone 15 Pro 시뮬레이터 UDID; 없으면 `xcrun simctl list devices available`에서 iPhone 시뮬레이터 UDID 선택). Expected: BUILD SUCCEEDED.
```bash
git add Projects/Features/StockFeature/Sources/Domain/Entity/Portfolio.swift Projects/Features/StockFeature/Sources/Data/DTO/PortfolioResponseDTO.swift Projects/Features/StockFeature/Sources/Domain/Repository Projects/Features/StockFeature/Sources/Data/Repository
git commit -m "feat(portfolio): add Portfolio entity, DTO fields, repository fetchPortfolio"
```

---

## Task 2: FetchPortfolioUsecase + StockClient.fetchPortfolio + Assembly

**Files:**
- Create: `StockFeature/Sources/Domain/UseCase/Interface/FetchPortfolioUsecase.swift`, `Impl/FetchPortfolioUsecaseImpl.swift`
- Modify: `StockFeature/Sources/Data/Dependency/StockClient.swift`, `StockAssembly.swift`

**Interfaces:**
- Consumes: `StockRepository.fetchPortfolio()` (Task 1).
- Produces: `StockClient.fetchPortfolio: @Sendable () async throws -> Portfolio` (PortfolioFeature가 사용).

- [ ] **Step 1: Usecase 생성** (mirror `FetchHoldingUsecase`)
```swift
// Interface/FetchPortfolioUsecase.swift
protocol FetchPortfolioUsecase: Sendable {
    func execute() async throws -> Portfolio
}
```
```swift
// Impl/FetchPortfolioUsecaseImpl.swift
struct FetchPortfolioUsecaseImpl: FetchPortfolioUsecase {
    private let stockRepository: any StockRepository
    init(stockRepository: any StockRepository) { self.stockRepository = stockRepository }
    func execute() async throws -> Portfolio {
        try await stockRepository.fetchPortfolio()
    }
}
```

- [ ] **Step 2: `StockClient`에 `fetchPortfolio` 추가**

`StockClient` struct의 `fetchHolding` 프로퍼티 아래에 추가:
```swift
    var fetchPortfolio: @Sendable () async throws -> Portfolio
```
`init(...)`의 파라미터 목록에 `fetchHolding` 다음으로 추가하고 대입:
```swift
        fetchPortfolio: @escaping @Sendable () async throws -> Portfolio,
        // ...
        self.fetchPortfolio = fetchPortfolio
```
`static func live(...)`의 파라미터에 `fetchPortfolioUsecase: any FetchPortfolioUsecase` 추가하고 클로저 배선:
```swift
            fetchPortfolio: {
                try await fetchPortfolioUsecase.execute()
            },
```
(`StockClientKey`/`DependencyValues` 확장은 그대로 둔다.)

- [ ] **Step 3: `StockAssembly` 배선**

`let fetchHoldingUsecase = ...` 아래에 추가:
```swift
        let fetchPortfolioUsecase = FetchPortfolioUsecaseImpl(stockRepository: stockRepository)
```
`StockClient.live(...)` 호출 인자에 추가:
```swift
            fetchPortfolioUsecase: fetchPortfolioUsecase,
```

- [ ] **Step 4: 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme StockFeature -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED. (init 파라미터 추가로 인한 다른 `StockClient(...)` 생성 지점이 있으면 함께 갱신 — grep `StockClient(` 로 확인.)
```bash
git add Projects/Features/StockFeature/Sources/Domain/UseCase Projects/Features/StockFeature/Sources/Data/Dependency
git commit -m "feat(portfolio): wire fetchPortfolio usecase into StockClient"
```

---

## Task 3: PortfolioFeature (Reducer) + 테스트

**Files:**
- Create: `StockFeature/Sources/Presentation/Portfolio/PortfolioFeature.swift`
- Modify: `StockFeature/Tests/Sources/StockFeatureTests.swift`

**Interfaces:**
- Consumes: `StockClient.fetchPortfolio` (Task 2), `StockClient.fetchStock` (existing), `Portfolio`(Task 1), `Stock`, `StockDetailFeature`.
- Produces: `PortfolioFeature` with State(`portfolio: Portfolio?`, `isLoading`, `errorMessage`, `@Presents detail: StockDetailFeature.State?`), Action `holdingTapped(String)` → fetch stock → presents detail.

- [ ] **Step 1: 실패 테스트 작성** (`StockFeatureTests.swift`에 추가; 파일 상단 import/스타일은 기존을 따른다)
```swift
@MainActor
final class PortfolioFeatureTests: XCTestCase {
    private func holding(_ code: String, profit: Int) -> StockHolding {
        StockHolding(stockCode: code, stockName: "종목\(code)", quantity: 10, averagePrice: 70_000,
                     currentPrice: 75_000, evaluationAmount: 750_000, profitAmount: profit, profitRate: 7.1)
    }
    private func portfolio() -> Portfolio {
        Portfolio(cashBalance: 9_250_000, totalStockValue: 750_000, totalAsset: 10_000_000,
                  profitAmount: 50_000, profitRate: 0.5, holdings: [holding("005930", profit: 50_000)])
    }

    func test_onAppear_loadsPortfolio() async {
        let p = portfolio()
        let store = TestStore(initialState: PortfolioFeature.State()) { PortfolioFeature() }
        store.dependencies.stockClient.fetchPortfolio = { p }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.portfolioLoaded(p)) {
            $0.isLoading = false
            $0.portfolio = p
        }
    }

    func test_onAppear_failureSetsError() async {
        struct Boom: Error {}
        let store = TestStore(initialState: PortfolioFeature.State()) { PortfolioFeature() }
        store.dependencies.stockClient.fetchPortfolio = { throw Boom() }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "포트폴리오를 불러오지 못했습니다."
        }
    }

    func test_holdingTapped_fetchesStockAndPresentsDetail() async {
        let stock = Stock(stockCode: "005930", stockName: "삼성전자", market: "KOSPI", currentPrice: 75_000,
                          changePrice: 100, changeRate: Decimal(string: "0.13"), tradeVolume: 1, tradeAmount: 1,
                          priceChangedAt: "2026-06-30T10:00:00")
        let store = TestStore(initialState: PortfolioFeature.State()) { PortfolioFeature() }
        store.dependencies.stockClient.fetchStock = { _ in stock }

        await store.send(.holdingTapped("005930"))
        await store.receive(.stockLoaded(stock)) {
            $0.detail = StockDetailFeature.State(stock: stock)
        }
    }
}
```
> 참고: `store.dependencies.stockClient.X = ...` 오버라이드 방식은 기존 StockFeature 테스트를 따른다. 기존 테스트가 별도 testValue/헬퍼를 쓰면 동일 방식으로 맞춘다. detail presentation 비교를 위해 `StockDetailFeature.State`가 `Equatable`이어야 한다(이미 그러함).

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -scheme StockFeature -destination 'id=<sim>'`. Expected: 컴파일 실패(PortfolioFeature 미정의).

- [ ] **Step 3: `PortfolioFeature` 구현**
```swift
import ComposableArchitecture

@Reducer
public struct PortfolioFeature {
    @Dependency(\.stockClient) private var stockClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var portfolio: Portfolio?
        public var isLoading: Bool
        public var errorMessage: String?
        @Presents public var detail: StockDetailFeature.State?

        public init(portfolio: Portfolio? = nil, isLoading: Bool = false,
                    errorMessage: String? = nil, detail: StockDetailFeature.State? = nil) {
            self.portfolio = portfolio
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.detail = detail
        }

        var isEmptyStateVisible: Bool {
            !isLoading && errorMessage == nil && (portfolio?.holdings.isEmpty ?? false)
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case portfolioLoaded(Portfolio)
        case loadFailed
        case holdingTapped(String)
        case stockLoaded(Stock)
        case stockLoadFailed
        case detail(PresentationAction<StockDetailFeature.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.portfolio == nil, !state.isLoading else { return .none }
                return load(&state)

            case .refresh:
                return load(&state)

            case let .portfolioLoaded(portfolio):
                state.isLoading = false
                state.errorMessage = nil
                state.portfolio = portfolio
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "포트폴리오를 불러오지 못했습니다."
                return .none

            case let .holdingTapped(stockCode):
                let stockClient = stockClient
                return .run { send in
                    do {
                        let stock = try await stockClient.fetchStock(stockCode)
                        await send(.stockLoaded(stock))
                    } catch {
                        await send(.stockLoadFailed)
                    }
                }

            case let .stockLoaded(stock):
                state.detail = StockDetailFeature.State(stock: stock)
                return .none

            case .stockLoadFailed:
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            StockDetailFeature()
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let stockClient = stockClient
        return .run { send in
            do {
                let portfolio = try await stockClient.fetchPortfolio()
                await send(.portfolioLoaded(portfolio))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
```

- [ ] **Step 4: 테스트 통과 확인** — Run: `xcodebuild test -scheme StockFeature -destination 'id=<sim>'`. Expected: PASS(신규 3개 + 기존 36개 모두).

- [ ] **Step 5: Commit**
```bash
git add Projects/Features/StockFeature/Sources/Presentation/Portfolio/PortfolioFeature.swift Projects/Features/StockFeature/Tests/Sources/StockFeatureTests.swift
git commit -m "feat(portfolio): add PortfolioFeature reducer with tests"
```

---

## Task 4: PortfolioView

**Files:**
- Create: `StockFeature/Sources/Presentation/Portfolio/PortfolioView.swift`

**Interfaces:**
- Consumes: `PortfolioFeature` (Task 3), `StockDetailView`(existing).

- [ ] **Step 1: 뷰 구현**

`public struct PortfolioView: View` (기본 store: `Store(initialState: PortfolioFeature.State()) { PortfolioFeature() }` — App 탭에서 인자 없이 생성). 구성:
- `@Bindable var store = store` (navigationDestination 바인딩용, StockView 패턴).
- `ScrollView` + 상단 **요약 카드**: `portfolio?.totalAsset`(총자산, 크게) · `profitAmount`+`profitRate%`(이익 `Color.tumoUp`/손실 `Color.tumoDown`) · `cashBalance`(현금) · `totalStockValue`(보유평가액). 숫자는 `.formatted()` + "원".
- **보유 목록**: `ForEach(portfolio.holdings, id: \.stockCode)` → 각 행 Button → `store.send(.holdingTapped(holding.stockCode))`; 행 라벨 = 종목명 · "\(quantity)주" · 평단/현재가 · `evaluationAmount`원 · `profitAmount`(+부호)·`profitRate%`(이익 tumoUp/손실 tumoDown). 행 사이 hairline(StockView 패턴).
- `.refreshable { store.send(.refresh) }`, `.task { store.send(.onAppear) }`.
- 상태 분기: 로딩(초기)·에러(`errorMessage`, 재시도 버튼 → `.refresh`)·빈(`isEmptyStateVisible` → "보유 종목이 없습니다"; 요약 카드의 현금/총자산은 표시).
- 네비게이션: `.navigationDestination(item: $store.scope(state: \.detail, action: \.detail)) { StockDetailView(store: $0) }` (StockView와 동일).
- 색상/타이포는 캐노니컬 CoreDesignSystem 토큰(`Color.tumoUp`/`tumoDown`/`tumoInk`/`tumoBody`/`tumoMuted`/`tumoHairlineSoft`/`tumoCanvas`)을 `import CoreDesignSystem`으로 직접 사용. private tumoUp/tumoDown 재정의 금지.
- `#Preview`로 보유 있음/빈 상태 2개(선택).

> 뷰는 자동 테스트 대상 아님. 컴파일/프리뷰로 확인.

- [ ] **Step 2: 빌드/프리뷰 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme StockFeature -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/Features/StockFeature/Sources/Presentation/Portfolio/PortfolioView.swift
git commit -m "feat(portfolio): add PortfolioView with summary, holdings list, detail navigation"
```

---

## Task 5: App '포트폴리오' 탭 연결

**Files:**
- Modify: `Projects/App/Sources/MainView.swift`

**Interfaces:**
- Consumes: `PortfolioView` (Task 4).

- [ ] **Step 1: 탭 콘텐츠 교체**

`MainView.swift`의 `MainTabContentView`에서 `.portfolio`를 placeholder에서 분리해 `PortfolioView()`로 연결:
```swift
        case .portfolio:
            PortfolioView()
```
(`.home, .my`는 placeholder 유지. `import StockFeature`는 이미 있음.)

- [ ] **Step 2: 앱 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -scheme Tumo -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/App/Sources/MainView.swift
git commit -m "feat(portfolio): show PortfolioView in portfolio tab"
```

---

## Task 6: 전체 검증

- [ ] **Step 1: 전체 테스트/빌드** — Run: `xcodebuild test -scheme StockFeature -destination 'id=<sim>'`(신규 3 + 기존 36 통과) 및 `xcodebuild -scheme Tumo -destination 'id=<sim>' build`(성공).
- [ ] **Step 2: 수동 시나리오** (로그인 상태) — 포트폴리오 탭 진입 → 총자산·손익·현금·보유 목록 표시 / 당겨서 새로고침 / 보유 0일 때 빈 상태 / 행 탭 → 종목 상세 이동(추가 매수/매도 가능) / 로드 실패 시 에러+재시도.
- [ ] **Step 3: 최종 커밋/푸시** (요청 시) — 브랜치 `feat/portfolio-tab` 푸시 후 PR.

---

## Self-Review (작성자 점검 결과)

- **스펙 커버리지**: 데이터계층(엔티티/DTO/Repository/Usecase/Client)=Task 1·2, 화면(요약+목록+새로고침+빈/에러)=Task 3·4, 행 탭→상세=Task 3(reducer)+4(view), 탭 연결=Task 5, 검증=Task 6. 전부 존재.
- **스펙 대비 축소**: `StockDataSource.fetchPortfolio()`가 이미 존재 → DataSource 변경 불필요(스펙의 "DataSource.portfolio 추가"는 불요). Global/Task에 반영.
- **타입 일관성**: `Portfolio`(cashBalance/totalStockValue/totalAsset/profitAmount/profitRate/holdings), `StockRepository.fetchPortfolio()`, `StockClient.fetchPortfolio`, `PortfolioFeature.Action.holdingTapped(String)`/`stockLoaded(Stock)`가 정의(1·2·3)와 사용(3·4)에서 일치. 네비게이션은 StockFeature의 `@Presents detail`/`.navigationDestination` 패턴과 동일.
- **구현자 확인 필요(메모)**: ① 시뮬레이터 UDID(iPhone 15 Pro `45CBB754-...` 없으면 대체), ② `StockClient(` 다른 생성 지점 존재 시 init 인자 갱신, ③ PortfolioFeatureTests의 stockClient 오버라이드 방식은 기존 StockFeature 테스트 패턴을 따를 것.
