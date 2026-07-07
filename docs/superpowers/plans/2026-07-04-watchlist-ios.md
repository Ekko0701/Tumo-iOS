# 관심종목 iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** StockFeature에 관심종목을 추가한다 — 종목 상세 헤더의 ★ 낙관적 토글과 종목 탭의 '관심' 세그먼트.

**Architecture:** 새 모듈 없이 기존 **StockFeature**의 세로 슬라이스(API→DataSource→Repository→Usecase→Client→Assembly)에 4개 오퍼레이션을 추가한다. 관심종목 목록 응답은 백엔드가 기존 종목 목록과 동일한 `StockPageResponse` 형태로 주므로 **기존 `StockPageResponseDTO`/`StockPage`를 그대로 재사용**한다(신규 페이지 타입 없음). 종목 상세는 `loadHolding` 패턴을 미러해 관심 여부를 조회하고, ★ 탭 시 낙관적으로 토글한다.

**Tech Stack:** Swift 6, SwiftUI, TCA, Tuist. JWT는 `TumoProviderFactory.live.authorizedProvider()`. 테스트 XCTest + `TestStore`.

## Global Constraints

- **백엔드 계약**(이미 구현·PR #6): `GET /api/v1/watchlist?page&size` → `StockPageResponse{stocks,page,size,hasNext}`; `GET /api/v1/watchlist/{stockCode}` → `{ "watched": true/false }`; `POST /api/v1/watchlist/{stockCode}` → 201 (바디 없음, 멱등); `DELETE /api/v1/watchlist/{stockCode}` → 204 (바디 없음, 멱등). 모두 JWT.
- **목록 응답 재사용**: `fetchWatchlist`는 `StockPage`를 반환한다. DataSource는 **기존 `StockPageResponseDTO`**로 디코딩하고, Repository는 **기존 `.toEntity()`**(fetchStocks가 쓰는 것)로 매핑한다. **신규 `WatchlistPage`/`WatchlistPageResponseDTO`를 만들지 말 것.**
- **관심 여부 조회**: `GET /watchlist/{code}` → 신규 `WatchedResponseDTO { watched: Bool }` 디코딩 → `Bool`. (404 추론 금지 — 백엔드가 명시적으로 `{watched}`를 준다.)
- **추가/삭제**: 201/204는 **빈 바디**이므로 디코딩하지 말고 `provider.requestData(.addToWatchlist(...))` / `.removeFromWatchlist(...)`로 호출하고 결과를 버린다(기존 AuthFeature logout의 `_ = try await provider.requestData(.logout)`와 동일). `EmptyResponse` 같은 타입 만들지 말 것. API task는 `.requestPlain`.
- **경로**: add/remove/watched 모두 `stockCode`를 **경로 변수**로(`/api/v1/watchlist/{stockCode}`). add는 바디 없음.
- **★ 낙관적 토글**: `StockDetailFeature.State.isWatched: Bool?`(nil=로딩 전). `starTapped` 시 즉시 `isWatched` 반전 후 add/remove 호출, 실패 시 이전 값으로 원복(`watchlistToggleFailed(Bool)`). `isWatched == nil`이면 토글 무시.
- **★ 색상**: 채워진 별 `star.fill` = `Color.tumoUp`(빨강), 빈 별 `star` = `Color.tumoMuted`. private tumoUp/tumoDown 재정의 금지, 캐노니컬 `CoreDesignSystem` 토큰만.
- **세그먼트**: `StockSortOption`에 `.watchlist`("관심") 추가. `rankingType`은 `.watchlist`에서 사용 안 함(기존 스위치가 rankingType을 쓰면 옵셔널화 또는 해당 케이스 분기). 선택 시 랭킹/목록 대신 `fetchWatchlist(0, size)` 호출 — **기존 로딩·페이지네이션 경로를 최대한 재사용**(새 isLoading 필드 추가 지양). 빈 상태: "관심종목이 없어요. 종목 상세에서 ★을 눌러 추가해 보세요."
- **testValue**: `StockClientKey`엔 이미 `testValue`가 있다(이전 기능에서 추가). 신규 4개 클로저를 여기에도 추가한다(add/remove는 `{ _ in }`, fetch류는 `fatalError("unimplemented")`).
- **코딩 규칙**: `let` 우선, `Sendable`, 기존 Clean Arch + TCA 컨벤션.
- **시뮬레이터**: `id=45CBB754-7B38-41C2-B381-8EB648D8D344`(이하 `<sim>`). 소스 추가 후 `tuist generate`. 테스트/빌드는 `-workspace Tumo.xcworkspace -scheme StockFeature`.
- **브랜치**: `feat/watchlist`(iOS repo, 이미 생성·스펙 커밋됨). 각 태스크 끝에 커밋. 최종 push/PR 별도.

---

## File Structure

**신규**
- `StockFeature/Sources/Data/DTO/WatchedResponseDTO.swift` — `{ watched: Bool }`
- `StockFeature/Sources/Domain/UseCase/Interface/`(+Impl/) — `FetchWatchlistUsecase`, `FetchWatchedUsecase`, `AddToWatchlistUsecase`, `RemoveFromWatchlistUsecase` (각 interface+impl)

**수정**
- `Data/API/StockAPI.swift` — 4 case
- `Data/DataSource/Interface/StockDataSource.swift` + `Impl/StockDataSourceImpl.swift` — 4 메서드
- `Domain/Repository/Interface/StockRepository.swift` + `Data/Repository/Impl/StockRepositoryImpl.swift` — 4 메서드
- `Data/Dependency/StockClient.swift` — 4 클로저 + init + live + testValue
- `Data/Dependency/StockAssembly.swift` — 4 usecase 배선
- `Presentation/StockDetail/Feature/StockDetailFeature.swift` + `View/StockDetailView.swift` — ★ 토글
- `Presentation/Stock/Feature/StockFeature.swift` + `View/StockView.swift` — 관심 세그먼트
- `Tests/Sources/StockFeatureTests.swift` — 신규 테스트

---

## Task 1: 데이터 엣지 — StockAPI 4 case + WatchedResponseDTO + DataSource

**Files:**
- Modify: `Projects/Features/StockFeature/Sources/Data/API/StockAPI.swift`
- Create: `Projects/Features/StockFeature/Sources/Data/DTO/WatchedResponseDTO.swift`
- Modify: `Projects/Features/StockFeature/Sources/Data/DataSource/Interface/StockDataSource.swift`
- Modify: `Projects/Features/StockFeature/Sources/Data/DataSource/Impl/StockDataSourceImpl.swift`

**Interfaces:**
- Consumes: 기존 `Provider<StockAPI>`(`request(_:as:)`, `requestData(_:)`), 기존 `StockPageResponseDTO`.
- Produces: `StockDataSource.{fetchWatchlist(page:size:) -> StockPageResponseDTO, fetchWatched(stockCode:) -> Bool, addToWatchlist(stockCode:), removeFromWatchlist(stockCode:)}`; `WatchedResponseDTO { watched: Bool }`.

- [ ] **Step 1: `StockAPI`에 4 case 추가**

case 목록에 추가:
```swift
    case fetchWatchlist(page: Int, size: Int)
    case fetchWatched(stockCode: String)
    case addToWatchlist(stockCode: String)
    case removeFromWatchlist(stockCode: String)
```
`path` switch에 추가:
```swift
        case .fetchWatchlist:
            "/api/v1/watchlist"
        case .fetchWatched(let stockCode):
            "/api/v1/watchlist/\(stockCode)"
        case .addToWatchlist(let stockCode):
            "/api/v1/watchlist/\(stockCode)"
        case .removeFromWatchlist(let stockCode):
            "/api/v1/watchlist/\(stockCode)"
```
`method`가 전 case `.get`였다면 아래로 분기 교체:
```swift
    var method: HTTPMethod {
        switch self {
        case .stocks, .rankings, .stock, .realtimePriceStream, .realtimeOrderBookStream, .candles,
             .fetchWatchlist, .fetchWatched:
            .get
        case .addToWatchlist:
            .post
        case .removeFromWatchlist:
            .delete
        }
    }
```
`task` switch에 추가:
```swift
        case .fetchWatchlist(let page, let size):
            .requestParameters(
                [
                    "page": page,
                    "size": size
                ],
                encoding: .url
            )
        case .fetchWatched, .addToWatchlist, .removeFromWatchlist:
            .requestPlain
```

- [ ] **Step 2: `WatchedResponseDTO` 생성**
```swift
import Foundation

/// `GET /api/v1/watchlist/{stockCode}` 응답. 관심 등록 여부.
struct WatchedResponseDTO: Decodable, Sendable, Equatable {
    let watched: Bool
}
```

- [ ] **Step 3: `StockDataSource` 프로토콜에 4 메서드 추가**

`fetchStocks(...)` 인근에 추가(반환 타입은 기존 목록과 동일한 `StockPageResponseDTO` 재사용):
```swift
    /// 관심종목 목록을 조회한다. (백엔드가 종목 목록과 동일한 StockPageResponse 형태로 응답)
    func fetchWatchlist(page: Int, size: Int) async throws -> StockPageResponseDTO

    /// 종목의 관심 등록 여부를 조회한다.
    func fetchWatched(stockCode: String) async throws -> Bool

    /// 관심종목을 추가한다.
    func addToWatchlist(stockCode: String) async throws

    /// 관심종목을 제거한다.
    func removeFromWatchlist(stockCode: String) async throws
```

- [ ] **Step 4: `StockDataSourceImpl`에 4 메서드 구현**

기존 `fetchStocks`의 `provider.request(..., as: StockPageResponseDTO.self)` 패턴을 확인해 미러한다. `provider`(StockAPI용)를 사용:
```swift
    func fetchWatchlist(page: Int, size: Int) async throws -> StockPageResponseDTO {
        try await provider.request(
            .fetchWatchlist(page: page, size: size),
            as: StockPageResponseDTO.self
        )
    }

    func fetchWatched(stockCode: String) async throws -> Bool {
        let dto = try await provider.request(
            .fetchWatched(stockCode: stockCode),
            as: WatchedResponseDTO.self
        )
        return dto.watched
    }

    func addToWatchlist(stockCode: String) async throws {
        _ = try await provider.requestData(.addToWatchlist(stockCode: stockCode))
    }

    func removeFromWatchlist(stockCode: String) async throws {
        _ = try await provider.requestData(.removeFromWatchlist(stockCode: stockCode))
    }
```
> `provider`의 정확한 프로퍼티명은 기존 `fetchStocks`가 쓰는 것과 동일하게(StockAPI 요청용 provider). 관심 API는 인증 필요하므로 authorizedProvider 경로(기존 stocks와 동일 provider)를 탄다.

- [ ] **Step 5: 빌드 확인 + Commit**

Run: `cd /Users/kimdongjoo/Desktop/Tumo/Tumo-iOS && tuist generate && xcodebuild -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/Features/StockFeature/Sources/Data/API/StockAPI.swift Projects/Features/StockFeature/Sources/Data/DTO/WatchedResponseDTO.swift Projects/Features/StockFeature/Sources/Data/DataSource
git commit -m "feat(watchlist): add watchlist StockAPI cases, WatchedResponseDTO, DataSource methods"
```

---

## Task 2: Repository + Usecase + StockClient + Assembly 배선

**Files:**
- Modify: `Domain/Repository/Interface/StockRepository.swift`, `Data/Repository/Impl/StockRepositoryImpl.swift`
- Create: `Domain/UseCase/Interface/{FetchWatchlist,FetchWatched,AddToWatchlist,RemoveFromWatchlist}Usecase.swift` + `Impl/*Impl.swift`
- Modify: `Data/Dependency/StockClient.swift`, `Data/Dependency/StockAssembly.swift`

**Interfaces:**
- Consumes: `StockDataSource` 4메서드(Task 1), 기존 `StockPage`/`.toEntity()`.
- Produces: `StockClient.{fetchWatchlist(_:_:) -> StockPage, fetchWatched(_:) -> Bool, addToWatchlist(_:), removeFromWatchlist(_:)}` (프레젠테이션이 사용).

- [ ] **Step 1: `StockRepository` 프로토콜에 4 메서드 추가**
```swift
    func fetchWatchlist(page: Int, size: Int) async throws -> StockPage
    func fetchWatched(stockCode: String) async throws -> Bool
    func addToWatchlist(stockCode: String) async throws
    func removeFromWatchlist(stockCode: String) async throws
```

- [ ] **Step 2: `StockRepositoryImpl`에 구현**

기존 `fetchStocks`가 `StockPageResponseDTO.toEntity() -> StockPage`로 매핑하는 것을 확인해 재사용:
```swift
    func fetchWatchlist(page: Int, size: Int) async throws -> StockPage {
        let responseDTO = try await stockDataSource.fetchWatchlist(page: page, size: size)
        return responseDTO.toEntity()
    }

    func fetchWatched(stockCode: String) async throws -> Bool {
        try await stockDataSource.fetchWatched(stockCode: stockCode)
    }

    func addToWatchlist(stockCode: String) async throws {
        try await stockDataSource.addToWatchlist(stockCode: stockCode)
    }

    func removeFromWatchlist(stockCode: String) async throws {
        try await stockDataSource.removeFromWatchlist(stockCode: stockCode)
    }
```
> `StockPageResponseDTO.toEntity()`가 이미 존재(fetchStocks가 사용). 없으면 fetchStocks 매핑 방식을 그대로 따른다. 신규 매핑 타입 만들지 말 것.

- [ ] **Step 3: Usecase 4쌍 생성** (mirror `FetchStocksUsecase`)
```swift
// Interface/FetchWatchlistUsecase.swift
protocol FetchWatchlistUsecase: Sendable {
    func execute(page: Int, size: Int) async throws -> StockPage
}
// Impl/FetchWatchlistUsecaseImpl.swift
struct FetchWatchlistUsecaseImpl: FetchWatchlistUsecase {
    private let stockRepository: any StockRepository
    init(stockRepository: any StockRepository) { self.stockRepository = stockRepository }
    func execute(page: Int, size: Int) async throws -> StockPage {
        try await stockRepository.fetchWatchlist(page: page, size: size)
    }
}
```
```swift
// Interface/FetchWatchedUsecase.swift
protocol FetchWatchedUsecase: Sendable {
    func execute(stockCode: String) async throws -> Bool
}
// Impl/FetchWatchedUsecaseImpl.swift
struct FetchWatchedUsecaseImpl: FetchWatchedUsecase {
    private let stockRepository: any StockRepository
    init(stockRepository: any StockRepository) { self.stockRepository = stockRepository }
    func execute(stockCode: String) async throws -> Bool {
        try await stockRepository.fetchWatched(stockCode: stockCode)
    }
}
```
```swift
// Interface/AddToWatchlistUsecase.swift
protocol AddToWatchlistUsecase: Sendable {
    func execute(stockCode: String) async throws
}
// Impl/AddToWatchlistUsecaseImpl.swift
struct AddToWatchlistUsecaseImpl: AddToWatchlistUsecase {
    private let stockRepository: any StockRepository
    init(stockRepository: any StockRepository) { self.stockRepository = stockRepository }
    func execute(stockCode: String) async throws {
        try await stockRepository.addToWatchlist(stockCode: stockCode)
    }
}
```
```swift
// Interface/RemoveFromWatchlistUsecase.swift
protocol RemoveFromWatchlistUsecase: Sendable {
    func execute(stockCode: String) async throws
}
// Impl/RemoveFromWatchlistUsecaseImpl.swift
struct RemoveFromWatchlistUsecaseImpl: RemoveFromWatchlistUsecase {
    private let stockRepository: any StockRepository
    init(stockRepository: any StockRepository) { self.stockRepository = stockRepository }
    func execute(stockCode: String) async throws {
        try await stockRepository.removeFromWatchlist(stockCode: stockCode)
    }
}
```

- [ ] **Step 4: `StockClient`에 4 클로저 + init + live + testValue**

struct에 프로퍼티 추가(`fetchCandles` 아래):
```swift
    public var fetchWatchlist: @Sendable (_ page: Int, _ size: Int) async throws -> StockPage
    public var fetchWatched: @Sendable (_ stockCode: String) async throws -> Bool
    public var addToWatchlist: @Sendable (_ stockCode: String) async throws -> Void
    public var removeFromWatchlist: @Sendable (_ stockCode: String) async throws -> Void
```
`init(...)` 파라미터 끝에 추가 + 본문 대입:
```swift
        fetchWatchlist: @escaping @Sendable (_ page: Int, _ size: Int) async throws -> StockPage,
        fetchWatched: @escaping @Sendable (_ stockCode: String) async throws -> Bool,
        addToWatchlist: @escaping @Sendable (_ stockCode: String) async throws -> Void,
        removeFromWatchlist: @escaping @Sendable (_ stockCode: String) async throws -> Void
```
```swift
        self.fetchWatchlist = fetchWatchlist
        self.fetchWatched = fetchWatched
        self.addToWatchlist = addToWatchlist
        self.removeFromWatchlist = removeFromWatchlist
```
`static func live(...)` 파라미터 끝에 추가 + 클로저 배선:
```swift
        fetchWatchlistUsecase: any FetchWatchlistUsecase,
        fetchWatchedUsecase: any FetchWatchedUsecase,
        addToWatchlistUsecase: any AddToWatchlistUsecase,
        removeFromWatchlistUsecase: any RemoveFromWatchlistUsecase
```
```swift
            fetchWatchlist: { page, size in
                try await fetchWatchlistUsecase.execute(page: page, size: size)
            },
            fetchWatched: { stockCode in
                try await fetchWatchedUsecase.execute(stockCode: stockCode)
            },
            addToWatchlist: { stockCode in
                try await addToWatchlistUsecase.execute(stockCode: stockCode)
            },
            removeFromWatchlist: { stockCode in
                try await removeFromWatchlistUsecase.execute(stockCode: stockCode)
            }
```
`private enum StockClientKey`의 기존 `testValue`에 4개 추가(마지막 프로퍼티들 뒤):
```swift
        fetchWatchlist: { _, _ in fatalError("unimplemented") },
        fetchWatched: { _ in fatalError("unimplemented") },
        addToWatchlist: { _ in },
        removeFromWatchlist: { _ in }
```

- [ ] **Step 5: `StockAssembly` 배선**

`let fetchCandlesUsecase = ...` 아래에 추가:
```swift
        let fetchWatchlistUsecase = FetchWatchlistUsecaseImpl(stockRepository: stockRepository)
        let fetchWatchedUsecase = FetchWatchedUsecaseImpl(stockRepository: stockRepository)
        let addToWatchlistUsecase = AddToWatchlistUsecaseImpl(stockRepository: stockRepository)
        let removeFromWatchlistUsecase = RemoveFromWatchlistUsecaseImpl(stockRepository: stockRepository)
```
`StockClient.live(...)` 호출 인자 끝에 추가:
```swift
            fetchWatchlistUsecase: fetchWatchlistUsecase,
            fetchWatchedUsecase: fetchWatchedUsecase,
            addToWatchlistUsecase: addToWatchlistUsecase,
            removeFromWatchlistUsecase: removeFromWatchlistUsecase
```

- [ ] **Step 6: 빌드 + 기존 테스트 확인 + Commit**

Run: `tuist generate && xcodebuild -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>' build && xcodebuild test -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>'`. Expected: BUILD SUCCEEDED, 기존 테스트 통과. (`StockClient(` 다른 생성 지점 있으면 grep으로 찾아 신규 인자 반영.)
```bash
git add Projects/Features/StockFeature/Sources/Domain/Repository Projects/Features/StockFeature/Sources/Data/Repository Projects/Features/StockFeature/Sources/Domain/UseCase Projects/Features/StockFeature/Sources/Data/Dependency
git commit -m "feat(watchlist): wire watchlist repository, usecases, StockClient, assembly"
```

---

## Task 3: StockDetailFeature — ★ 낙관적 토글 + 테스트

**Files:**
- Modify: `Projects/Features/StockFeature/Sources/Presentation/StockDetail/Feature/StockDetailFeature.swift`
- Modify: `Projects/Features/StockFeature/Tests/Sources/StockFeatureTests.swift`

**Interfaces:**
- Consumes: `StockClient.{fetchWatched, addToWatchlist, removeFromWatchlist}`(Task 2).
- Produces: `StockDetailFeature.State.isWatched: Bool?`, Actions `loadWatched`/`watchedLoaded(Bool)`/`watchedLoadFailed`/`starTapped`/`watchlistToggleFailed(Bool)`.

- [ ] **Step 1: 실패 테스트 작성** (`StockFeatureTests.swift`에 추가; 기존 StockDetailFeature 테스트의 TestStore·의존성 오버라이드 스타일을 그대로 따른다. `Self.sampleStock`가 있으면 재사용, 없으면 기존 테스트가 쓰는 샘플 생성 방식 사용)
```swift
    func test_watchdetail_starTapped_optimisticallyAddsThenReverts_onFailure() async {
        struct Boom: Error {}
        let store = TestStore(
            initialState: StockDetailFeature.State(stock: Self.sampleStock, isWatched: false)
        ) { StockDetailFeature() } withDependencies: {
            $0.stockClient.addToWatchlist = { _ in throw Boom() }
        }
        await store.send(.starTapped) { $0.isWatched = true }          // 낙관적 반영
        await store.receive(.watchlistToggleFailed(false)) { $0.isWatched = false } // 원복
    }

    func test_watchdetail_starTapped_optimisticallyRemoves_success() async {
        let store = TestStore(
            initialState: StockDetailFeature.State(stock: Self.sampleStock, isWatched: true)
        ) { StockDetailFeature() } withDependencies: {
            $0.stockClient.removeFromWatchlist = { _ in }
        }
        await store.send(.starTapped) { $0.isWatched = false }         // 낙관적 반영, 성공 시 후속 액션 없음
    }

    func test_watchdetail_loadWatched_setsState() async {
        let store = TestStore(
            initialState: StockDetailFeature.State(stock: Self.sampleStock)
        ) { StockDetailFeature() } withDependencies: {
            $0.stockClient.fetchWatched = { _ in true }
        }
        await store.send(.loadWatched)
        await store.receive(.watchedLoaded(true)) { $0.isWatched = true }
    }
```
> 참고: 낙관적 성공 경로는 후속 수신 액션이 없다(상태는 send에서 이미 반영). 실패 경로만 `watchlistToggleFailed` 수신. `starTapped` 시 `isWatched == nil`이면 아무 일도 없어야 한다(테스트 추가는 선택). 기존 상세 테스트가 `onAppear`로 스트림/보유를 함께 트리거하므로, 위 테스트는 `starTapped`/`loadWatched`를 직접 send해 격리한다.

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>'`. Expected: 컴파일 실패(신규 State/Action 미정의).

- [ ] **Step 3: State에 `isWatched` 추가**

`State`에 저장 프로퍼티 추가(기존 필드들 사이, 예: `orderBookRetryCount` 아래) + `init` 파라미터/대입 추가:
```swift
        public var isWatched: Bool?
```
init 파라미터(기본값 nil)와 대입을 기존 다른 옵셔널 필드와 동일하게 추가:
```swift
                    isWatched: Bool? = nil,
```
```swift
            self.isWatched = isWatched
```

- [ ] **Step 4: Action + 리듀서 핸들러 추가**

`Action`에 추가(보유 관련 액션 인근):
```swift
        case loadWatched
        case watchedLoaded(Bool)
        case watchedLoadFailed
        case starTapped
        case watchlistToggleFailed(Bool)
```
`onAppear`의 `.merge(...)`에 `loadWatched`를 추가(기존 `loadHolding`과 병렬):
```swift
            case .onAppear:
                return .merge(
                    .send(.startPriceStream),
                    state.isHoldingLoaded ? .none : .send(.loadHolding),
                    .send(.loadWatched),
                    effectOnEnter(tab: state.selectedTab, state: state)
                )
```
리듀서에 핸들러 추가(보유 핸들러 인근):
```swift
            case .loadWatched:
                let stockCode = state.stock.stockCode
                let stockClient = stockClient
                return .run { send in
                    do {
                        let watched = try await stockClient.fetchWatched(stockCode)
                        await send(.watchedLoaded(watched))
                    } catch {
                        await send(.watchedLoadFailed)
                    }
                }

            case let .watchedLoaded(watched):
                state.isWatched = watched
                return .none

            case .watchedLoadFailed:
                return .none

            case .starTapped:
                guard let current = state.isWatched else { return .none }
                let target = !current
                state.isWatched = target
                let stockCode = state.stock.stockCode
                let stockClient = stockClient
                return .run { send in
                    do {
                        if target {
                            try await stockClient.addToWatchlist(stockCode)
                        } else {
                            try await stockClient.removeFromWatchlist(stockCode)
                        }
                    } catch {
                        await send(.watchlistToggleFailed(current))
                    }
                }

            case let .watchlistToggleFailed(previous):
                state.isWatched = previous
                return .none
```
> `onAppear` merge에 `loadWatched` 추가 시, 기존 상세 테스트가 `.receive`로 액션 순서를 검증하면 그 테스트에 `.receive(.loadWatched)`/`.receive(.watchedLoaded(...))`가 필요해질 수 있다. 실패하면 기존 테스트에 fetchWatched 스텁 + 해당 receive를 추가해 정렬한다(실패 메시지대로).

- [ ] **Step 5: 테스트 통과 확인** — Run 위와 동일. Expected: 신규 3 + 기존 통과.

- [ ] **Step 6: Commit**
```bash
git add Projects/Features/StockFeature/Sources/Presentation/StockDetail/Feature/StockDetailFeature.swift Projects/Features/StockFeature/Tests/Sources/StockFeatureTests.swift
git commit -m "feat(watchlist): add optimistic star toggle to StockDetailFeature with tests"
```

---

## Task 4: StockDetailView — ★ 버튼

**Files:**
- Modify: `Projects/Features/StockFeature/Sources/Presentation/StockDetail/View/StockDetailView.swift`

**Interfaces:**
- Consumes: `StockDetailFeature.State.isWatched`, Action `.starTapped`(Task 3).

- [ ] **Step 1: 헤더에 ★ 버튼 추가**

`header`의 최상단(뒤로가기 버튼이 있는 줄)을 `HStack`으로 감싸 오른쪽에 ★ 버튼을 둔다. `@Bindable var store` 또는 `store` 사용은 기존 뷰 방식을 따른다.
```swift
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)
                        .frame(width: 36, height: 36, alignment: .leading)
                }
                .buttonStyle(.plain)

                Spacer()

                if let isWatched = store.isWatched {
                    Button {
                        store.send(.starTapped)
                    } label: {
                        Image(systemName: isWatched ? "star.fill" : "star")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isWatched ? Color.tumoUp : Color.tumoMuted)
                            .frame(width: 36, height: 36, alignment: .trailing)
                    }
                    .buttonStyle(.plain)
                }
            }

            // ... 이하 기존 종목명/MarketBadge/코드/현재가 블록 그대로 유지 ...
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
```
> `isWatched == nil`(로딩 전)이면 별을 렌더하지 않는다(잠깐의 빈 별 깜빡임 방지). 나머지 헤더 내용(종목명 HStack, 코드, 현재가 VStack)은 기존 코드를 그대로 둔다. 색상은 캐노니컬 `Color.tumoUp`/`tumoMuted`.

- [ ] **Step 2: 빌드 확인 + Commit**

Run: `tuist generate && xcodebuild -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>' build`. Expected: BUILD SUCCEEDED.
```bash
git add Projects/Features/StockFeature/Sources/Presentation/StockDetail/View/StockDetailView.swift
git commit -m "feat(watchlist): add star toggle button to StockDetailView header"
```

---

## Task 5: 종목 탭 '관심' 세그먼트

**Files:**
- Modify: `Projects/Features/StockFeature/Sources/Presentation/Stock/Feature/StockFeature.swift`
- Modify: `Projects/Features/StockFeature/Sources/Presentation/Stock/View/StockView.swift` (빈 상태 문구만; 세그먼트는 `allCases`로 자동 노출)
- Modify: `Projects/Features/StockFeature/Tests/Sources/StockFeatureTests.swift`

**Interfaces:**
- Consumes: `StockClient.fetchWatchlist`(Task 2), 기존 로딩/`stocksLoaded` 경로.
- Produces: `StockSortOption.watchlist`.

- [ ] **Step 1: 실패 테스트 작성** (기존 StockFeature 테스트 스타일; `fetchWatchlist` 스텁 + realtime 스텁은 기존 로딩 테스트가 하는 방식대로)
```swift
    func test_stocklist_watchlistSegment_loadsWatchlist() async {
        let page = StockPage(stocks: [Self.sampleStock], page: 0, hasNext: false)
        let store = TestStore(initialState: StockFeature.State()) { StockFeature() } withDependencies: {
            $0.stockClient.fetchWatchlist = { p, s in
                XCTAssertEqual(p, 0)
                return page
            }
            $0.stockClient.observeRealtimePrices = { _ in .never }
        }
        // 관심 세그먼트 선택 → fetchWatchlist 호출 → 목록 반영.
        // 정확한 액션명(sortOptionChanged 등)과 후속 수신(stocksLoaded/startRealtimeUpdates)은
        // 기존 StockFeature 리듀서를 확인해 맞춘다. 아래는 기대 형태:
        await store.send(.sortOptionChanged(.watchlist)) { $0.sortOption = .watchlist; $0.isLoading = true; $0.stocks = [] }
        await store.receive(.stocksLoaded(page)) { $0.isLoading = false; $0.stocks = page.stocks }
        await store.receive(.startRealtimeUpdates)
        await store.send(.onDisappear)
    }
```
> 이 테스트의 액션·수신 순서는 **기존 StockFeature 리듀서의 실제 흐름에 맞춰 조정**한다(현재 `sortOptionChanged`가 어떤 후속 액션을 내는지 확인). realtime 구독이 없다면 그 수신·`onDisappear`는 제거.

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>'`. Expected: 컴파일 실패(`.watchlist` 미정의).

- [ ] **Step 3: `StockSortOption`에 `.watchlist` 추가**

`StockSortOption` enum에 case + title 추가:
```swift
    case watchlist
```
```swift
        case .watchlist:
            "관심"
```
`rankingType`이 non-optional이면 `.watchlist`에서 컴파일되도록 처리: 스위치가 `StockRankingType`를 반환한다면 반환 타입을 `StockRankingType?`로 바꾸고 `.watchlist → nil`. 그 사용처(랭킹 로드)에서 `.watchlist`는 별도 분기(아래 Step 4)로 처리하므로 nil 케이스에 도달하지 않는다.

- [ ] **Step 4: 리듀서에서 `.watchlist` 분기**

기존 `sortOptionChanged`(또는 옵션 선택) 핸들러를 확인해, 선택이 `.watchlist`면 랭킹/목록 로드 대신 `fetchWatchlist`를 호출하도록 분기한다. **기존 로딩 이펙트 구조(isLoading 세팅, stocks 초기화, stocksLoaded 수신)를 그대로 재사용**하고 데이터 소스만 바꾼다. 예(기존 `load`류 헬퍼가 있으면 그 패턴을 따름):
```swift
            case let .sortOptionChanged(option):
                guard state.sortOption != option else { return .none }
                state.sortOption = option
                state.stocks = []
                state.isLoading = true
                state.errorMessage = nil
                let stockClient = stockClient
                if option == .watchlist {
                    return .run { send in
                        do {
                            let page = try await stockClient.fetchWatchlist(0, 30)
                            await send(.stocksLoaded(page))
                        } catch {
                            await send(.stocksFailed("관심종목을 불러오지 못했습니다."))
                        }
                    }
                }
                // 기존 랭킹/목록 로드 경로 유지 (option.rankingType 사용)
                return <기존 로드 이펙트>
```
> 위는 형태 예시다. 실제 기존 핸들러의 액션명(`stocksLoaded`/`stocksFailed`/페이지네이션 커서 등)과 시그니처에 맞춰 정확히 통합한다. 페이지네이션(무한 스크롤)은 관심 목록에도 자연히 동작하면 유지하되, 커서/다음페이지 로직이 랭킹 전용이면 관심은 첫 페이지만 로드(size 넉넉히, 예 30~100)로 단순화하고 그 사실을 커밋 메시지에 남긴다.

- [ ] **Step 5: 빈 상태 문구** (`StockView.swift`)

기존 빈 상태(종목 0개) 뷰가 있으면, `store.sortOption == .watchlist`일 때 문구를 "관심종목이 없어요. 종목 상세에서 ★을 눌러 추가해 보세요."로 분기. 없으면 최소 빈 상태 추가. 세그먼트 자체는 `StockSortOption.allCases`로 자동 노출되므로 추가 작업 불필요.

- [ ] **Step 6: 테스트 통과 + 빌드 확인 + Commit**

Run: `xcodebuild test -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>'`. Expected: 신규 + 기존 통과.
```bash
git add Projects/Features/StockFeature/Sources/Presentation/Stock Projects/Features/StockFeature/Tests/Sources/StockFeatureTests.swift
git commit -m "feat(watchlist): add 관심 segment to stock tab"
```

---

## Task 6: 전체 검증

- [ ] **Step 1: 전체 테스트/빌드** — Run: `tuist generate && xcodebuild test -workspace Tumo.xcworkspace -scheme StockFeature -destination 'id=<sim>'` 및 `xcodebuild -workspace Tumo.xcworkspace -scheme Tumo -destination 'id=<sim>' build`. Expected: 전부 통과·성공. (신규 스킴 없음 — 기존 StockFeature 스킴 재사용.)
- [ ] **Step 2: 수동 시나리오** (로그인 + 백엔드 실행):
  - 종목 상세 진입 → ★ 초기 상태 로드 → ★ 탭 시 즉시 채워짐(낙관적) → 재진입 시 유지
  - ★ 다시 탭 → 즉시 빈 별 → 관심 해제
  - 종목 탭 '관심' 세그먼트 → 관심 등록 종목 목록(시세 포함), 행 탭 → 상세
  - 관심 0개 → 빈 상태 문구
  - (네트워크 실패 시 ★ 원복 확인)
- [ ] **Step 3: 최종 커밋/푸시** (요청 시) — 브랜치 `feat/watchlist` 푸시 후 PR.

---

## Self-Review (작성자 점검 결과)

- **스펙 커버리지**: 데이터 4오퍼레이션(API/DTO/DataSource=Task1, Repo/Usecase/Client/Assembly=Task2), 상세 ★ 낙관적 토글(Task3 리듀서·테스트 + Task4 뷰), 관심 세그먼트(Task5), 검증(Task6). 스펙 iOS 항목 전부 대응.
- **탐색 초안 대비 교정(중요)**: (1) 목록은 신규 `WatchlistPage`/DTO 대신 **기존 `StockPageResponseDTO`/`StockPage` 재사용**(백엔드가 StockPageResponse 반환). (2) `fetchWatched`는 **`WatchedResponseDTO{watched}` 디코딩**(404 추론 아님). (3) add/remove는 **`provider.requestData`**(EmptyResponse 타입 없음). (4) add 경로는 `/{stockCode}`(바디 없음). (5) 토글은 **낙관적**(즉시 반영 + `watchlistToggleFailed` 원복). (6) 새 `isLoadingWatchlist` 대신 기존 `isLoading` 재사용.
- **타입 일관성**: `StockClient.fetchWatchlist(_:_:) -> StockPage`·`fetchWatched(_:) -> Bool`·`addToWatchlist(_:)`·`removeFromWatchlist(_:)`가 정의(Task2)와 사용(Task3·5)에서 일치. `WatchedResponseDTO{watched:Bool}`, `StockSortOption.watchlist`, `StockDetailFeature.State.isWatched: Bool?` + 액션(`loadWatched`/`watchedLoaded`/`starTapped`/`watchlistToggleFailed`) 일관.
- **구현자 확인 필요(메모)**: ① Task1의 `provider` 프로퍼티명·`request(_:as:)`/`requestData(_:)` 시그니처는 기존 `fetchStocks`/logout 패턴에서 확인. ② `StockPageResponseDTO.toEntity()` 존재 확인(fetchStocks 사용) — 없으면 동일 매핑 재사용. ③ Task3 `onAppear` merge에 `loadWatched` 추가로 기존 상세 테스트의 `.receive` 순서가 바뀌면 그 테스트에 스텁+receive 추가. ④ Task5는 기존 `sortOptionChanged` 흐름(액션명·페이지네이션)을 실제 코드로 확인해 정확히 통합. ⑤ 시뮬레이터 UDID·`tuist generate` 후 `-workspace` 스킴 사용.
