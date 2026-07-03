# iOS 홈·내 정보 탭 설계

- **날짜**: 2026-07-03
- **상태**: 승인됨 (사용자 검토 대기)
- **대상**: `Tumo-iOS` — `MainView`에서 placeholder 상태인 `.home`(홈)·`.my`(내 정보) 탭을 실제 화면으로 채운다.

## 배경 & 목표

현재 `Projects/App/Sources/MainView.swift`의 5개 탭 중 홈·내 정보는 동일한 placeholder를 렌더한다. 나머지 세 탭(종목·주문·포트폴리오)은 각 feature 모듈의 **public View**로 구현돼 있다. 이번 작업은 두 탭을 다음으로 채운다:

- **홈**: 앱 진입 기본 탭. 자산 요약 + 등락률 상위 종목 + 최근 주문을 모은 **대시보드**.
- **내 정보**: **프로필 헤더 + 메뉴 리스트**(주문 내역·포트폴리오 바로가기, 로그아웃, 앱 정보).

신규 백엔드 작업은 없다. 모든 데이터는 기존 엔드포인트로 충당한다.

## 확정된 결정 (브레인스토밍)

1. **홈 = 대시보드 요약** (자산 카드 + 등락률 상위 랭킹 + 최근 주문)
2. **내 정보 = 프로필 + 메뉴** (`/users/me` 조회 필요)
3. **새 feature 모듈 2개** 생성 (`HomeFeature`, `MyInfoFeature`)

## 아키텍처

### 모듈 & 의존성

| 모듈 | 신규/확장 | 의존성 | 소비 Client |
|------|-----------|--------|-------------|
| `HomeFeature` | 신규 | `StockFeature`, `OrderFeature`, `CoreDesignSystem`, TCA | `stockClient`(포트폴리오·랭킹), `orderClient`(최근 주문) |
| `MyInfoFeature` | 신규 | `AuthFeature`, `OrderFeature`, `StockFeature`, `CoreDesignSystem`, TCA | `authClient`(fetchMe·logout) |
| `AuthFeature` | 확장 | (기존) | `AuthClient`에 `fetchMe`·`logout` 추가 |
| `StockFeature` | 공개 범위 변경 | (기존) | `StockClient`·접근자 public화, `StockDetailFeature.State`/`init` public 확인 |
| `OrderFeature` | 공개 범위 변경 | (기존) | `OrderClient`·접근자 public화 |
| `App` | 수정 | +`HomeFeature`, `MyInfoFeature` import | 라우팅·로그아웃 배선 |

`TumoModule.swift`에 `homeFeature`·`myInfoFeature` case 추가 + 각 모듈 `Project.swift` 생성.

### Public 노출 (기존 모듈 표면 변경)

새 모듈이 `@Dependency`로 기존 client를 쓰려면 아래를 `public`으로 노출한다. 이는 잘 설계된 의존성 client를 모듈 공개 계약으로 승격하는 것으로, TCA 관용에 부합한다.

- **`StockClient`**: `struct` 선언 + 모든 클로저형 프로퍼티 + `init` + `extension DependencyValues { var stockClient }` 접근자를 `public`화. `static func live`/`StockAssembly`는 내부 유지.
- **`OrderClient`**: 위와 동일 (`buy`/`sell`/`history` 프로퍼티 + init + 접근자). `testValue`는 내부 유지.
- **`StockDetailFeature`**: 이미 `public`. `State`와 `init(stock:)`, `Action`이 `public`인지 확인하고 아니면 노출 (홈 랭킹 행 탭 → 종목 상세 재사용).

반환 타입은 이미 public이다: `Portfolio`, `StockPage`, `Stock`, `StockMarket`, `StockRankingType`(StockFeature), `OrderPage`, `OrderHistoryItem`(OrderFeature), `AuthUser`(AuthFeature).

> Portfolio의 SwiftUI 컴포넌트(`PortfolioSummaryCard` 등)는 `internal`이므로 재사용하지 않고, 홈은 동일 톤의 자체 카드/행 컴포넌트를 만든다.

## AuthFeature 확장 (fetchMe + logout)

기존 Clean Architecture(API→DataSource→Repository→Usecase→Client→Assembly) 그대로 세로 슬라이스 2개 추가.

- **API**: `AuthAPI.me` (`GET /api/v1/users/me`, 인증), `AuthAPI.logout` (`POST /api/v1/auth/logout`, 인증)
- **DTO**: `MyUserResponseDTO { id: Int64, email: String, nickname: String, cashBalance: Int64 }` → `AuthUser` 매핑
- **DataSource**: `fetchMe() async throws -> AuthUser`, `logout() async throws`
- **Repository**: 위 두 메서드 인터페이스 + 구현
- **Usecase**:
  - `FetchMeUsecase.execute() -> AuthUser`
  - `LogoutUsecase.execute()`: **백엔드 로그아웃 best-effort 호출 → 성공/실패와 무관하게 `TokenStorageClient.delete()`로 Keychain 토큰 삭제** (로컬 로그아웃은 항상 성립)
- **AuthClient**: `fetchMe: () async throws -> AuthUser`, `logout: () async throws -> Void` 추가 + `AuthClient.live(...)`/`AuthAssembly.live()` 배선. `init`·`live` 시그니처 확장.

## HomeFeature (홈 대시보드)

### 상태 / 액션

```
@ObservableState State:
  portfolio: Portfolio?          // 자산 요약
  topMovers: [Stock]             // 등락률 상위 (최대 5)
  recentOrders: [OrderHistoryItem] // 최근 주문 (최대 5)
  isLoading: Bool
  errorMessage: String?
  @Presents stockDetail: StockDetailFeature.State?

Action:
  onAppear
  refresh                        // 당겨서 새로고침
  dataLoaded(Portfolio, [Stock], [OrderHistoryItem])
  loadFailed(String)
  stockTapped(Stock)
  stockDetail(PresentationAction<StockDetailFeature.Action>)
```

### 리듀서

- `onAppear`(최초 1회)·`refresh` → `.run`에서 **병렬 조회**(`async let`):
  - `stockClient.fetchPortfolio()`
  - `stockClient.fetchStockRankings(.kospi, .rising, 0, 5)` → `StockPage.stocks` 상위 5 (`.rising` = 전일 대비 급상승 = 등락률 상위. `StockRankingType`은 `popular`/`tradeAmount`/`tradeVolume`/`rising`/`falling`)
  - `orderClient.history(0, 5)` → `OrderPage.items` 상위 5
  - 셋을 `await`하여 `dataLoaded`; throw 시 `loadFailed`
- **v1 에러 정책**: 셋 중 하나라도 실패하면 통합 에러 + 재시도 (단순화). 섹션별 부분 실패 복원력은 범위 밖(향후 개선).
- `stockTapped` → `state.stockDetail = StockDetailFeature.State(stock:)`
- `.ifLet(\.$stockDetail, action: \.stockDetail) { StockDetailFeature() }`

### 뷰 (`HomeView`)

`NavigationStack`(MainView가 이미 제공) 내부 `ScrollView` + `.refreshable`:

1. **자산 요약 카드** — 총자산(큰 숫자) / 손익액·손익률(색: `tumoUp` 빨강 / `tumoDown` 파랑) / 보유현금. Portfolio 톤 모방한 자체 카드.
2. **"등락률 상위" 섹션** — 상위 5 종목 행(종목명 · 현재가 · 등락률% 색상). 행 탭 → 종목 상세.
3. **"최근 주문" 섹션** — 최근 5건(종목명 · 매수/매도 뱃지 · 수량 · 체결가). 비탭.
- 로딩 스켈레톤 / 에러(재시도 버튼) / 빈 상태(보유·주문 없음).
- `.navigationDestination(item: $store.scope(state: \.stockDetail, action: \.stockDetail))` → `StockDetailView`.

## MyInfoFeature (내 정보)

### 상태 / 액션

```
@ObservableState State:
  profile: AuthUser?
  isLoading: Bool
  errorMessage: String?
  didLogout: Bool                // View가 관찰 → onLoggedOut() 호출
  @Presents destination: Destination.State?   // .orders / .portfolio push
  @Presents alert: AlertState<Action.Alert>?   // 로그아웃 확인

Action:
  onAppear
  profileLoaded(AuthUser)
  loadFailed(String)
  menuTapped(MenuItem)           // .orders | .portfolio
  logoutTapped                   // → 확인 alert 표시
  alert(PresentationAction<Alert>)   // .confirmLogout
  logoutSucceeded
  destination(PresentationAction<Destination.Action>)
```

### 리듀서

- `onAppear`(최초 1회) → `authClient.fetchMe()` → `profileLoaded` / `loadFailed`
- `menuTapped(.orders)` → `destination = .orders`; `.portfolio` → `destination = .portfolio`
- `logoutTapped` → `alert = 확인 다이얼로그`(취소 / 로그아웃[destructive])
- `alert(.presented(.confirmLogout))` → `.run { authClient.logout() → logoutSucceeded }`
- `logoutSucceeded` → `state.didLogout = true`

### 뷰 (`MyInfoView(onLoggedOut:)`)

- **프로필 헤더 카드** — 닉네임(큰 semibold) · 이메일(muted) · 보유 현금(₩ 포맷)
- **메뉴 리스트** — 주문 내역 · 포트폴리오 · 앱 정보(버전, `Bundle` 정적) · 로그아웃(destructive)
- 로딩/에러 상태
- `.navigationDestination`으로 `.orders → OrderHistoryView()`, `.portfolio → PortfolioView()` push
- **`.onChange(of: store.didLogout)`**: true가 되면 `onLoggedOut()` 클로저 호출 (클로저를 State에 넣지 않아 `Equatable`/`TestStore` 안전)

## App 통합 (라우팅 + 로그아웃)

MainView가 store 없이 각 탭 View를 인스턴스화하는 현 구조를 유지하고, 로그아웃 신호만 상위로 전달.

- **`AppFeature`**: `Action.logout` 추가 → 핸들러에서 `state.route = .auth`, `state.auth = AuthFeature.State()`(초기화)
- **`RootView`**: `case .main: MainView(onLoggedOut: { store.send(.logout) })`
- **`MainView`**: `let onLoggedOut: () -> Void` 프로퍼티 추가; `MainTabContentView`에서
  - `.home → HomeView()`
  - `.my → MyInfoView(onLoggedOut: onLoggedOut)`
  - placeholder 제거. `#Preview`는 `MainView(onLoggedOut: {})`.

## 데이터 흐름 (홈)

```
HomeView.onAppear
  → HomeFeature.run
      async let portfolio = stockClient.fetchPortfolio()      // GET /api/v1/portfolio
      async let movers    = stockClient.fetchStockRankings(...) // GET /api/v1/stocks/rankings
      async let orders    = orderClient.history(0, 5)          // GET /api/v1/orders
  → dataLoaded → State 갱신 → 카드/섹션 렌더
```

로그아웃:
```
MyInfoView 로그아웃 → alert 확인 → authClient.logout()
  → LogoutUsecase: POST /auth/logout (best-effort) + TokenStorage.delete()
  → didLogout=true → onLoggedOut() → AppFeature.logout → route=.auth → AuthView
```

## 디자인 시스템

- 색: `tumoUp`(빨강, 상승/이익), `tumoDown`(파랑, 하락/손실) — 토스 관습. 등락률·손익 모두 적용.
- 토큰: `tumoInk`/`tumoBody`/`tumoMuted`(텍스트), `tumoHairline`(구분선), `tumoCanvas`(배경). 통화 포맷은 기존 Portfolio와 동일 방식.

## 에러 / 로딩 / 빈 상태

- **홈**: 통합 로딩 스켈레톤 → 성공 시 카드+섹션 / 실패 시 에러+재시도. 보유·주문 없음 시 각 섹션 빈 상태 문구.
- **내 정보**: 프로필 로딩 → 실패 시 에러+재시도. 로그아웃은 백엔드 실패해도 로컬 토큰 삭제로 진행.

## 테스트

- **HomeFeature**: 로드 성공(3종 합성 상태 검증) · 로드 실패(errorMessage) · 종목 탭→`stockDetail` presented
- **MyInfoFeature**: 프로필 로드 성공/실패 · 로그아웃 확인→`authClient.logout` 호출→`didLogout=true` · 메뉴 탭→destination
- **AuthFeature**: `FetchMeUsecase`(DTO→AuthUser 매핑) · `LogoutUsecase`(토큰 삭제 검증, 백엔드 실패해도 삭제)
- `TestStore` + `withDependencies`로 client 스텁 주입 (기존 패턴).

## 신규/수정 파일 (요약)

**신규 — HomeFeature 모듈**
- `Projects/Features/HomeFeature/Project.swift`
- `Sources/Presentation/HomeFeature.swift`, `HomeView.swift`
- `Sources/Presentation/Components/` (요약 카드·행 컴포넌트)
- `Tests/Sources/HomeFeatureTests.swift`

**신규 — MyInfoFeature 모듈**
- `Projects/Features/MyInfoFeature/Project.swift`
- `Sources/Presentation/MyInfoFeature.swift`, `MyInfoView.swift`
- `Tests/Sources/MyInfoFeatureTests.swift`

**신규 — AuthFeature 슬라이스**
- `MyUserResponseDTO.swift`, `AuthAPI`에 `.me`/`.logout` case
- DataSource/Repository 확장, `FetchMeUsecase(+Impl)`, `LogoutUsecase(+Impl)`
- `AuthFeatureTests`에 usecase 테스트

**수정**
- `Tuist/ProjectDescriptionHelpers/TumoModule.swift` (모듈 2개 등록)
- `StockClient.swift`·`OrderClient.swift` public화, `StockDetailFeature` State/init 노출 확인
- `AuthClient.swift`/`AuthAssembly.swift` (fetchMe·logout 배선)
- `Projects/App/Sources/MainView.swift`, `RootView.swift`, `AppFeature.swift`
- `Projects/App/Project.swift` (HomeFeature·MyInfoFeature 의존 추가)

## 엣지 케이스

- **홈 데이터 일부 없음**: 보유 0 → 자산 카드 0원 표기, 랭킹/주문 빈 상태. 조회 자체 실패만 에러 처리.
- **랭킹 등락률 nil**: `changeRate`가 nil인 종목은 등락률 "—" 표기(시세 미제공).
- **재로그인 필요**: `fetchMe`/`fetchPortfolio`가 401 → 기존 인터셉터의 토큰 갱신에 위임(범위 밖).
- **로그아웃 중복 탭**: `isLoading`/effect 취소로 중복 방지.

## 범위 밖 (YAGNI)

- 시장 지수, 관심종목/즐겨찾기, 뉴스 피드 (백엔드 미구현)
- 프로필 수정(닉네임·비밀번호), 알림 설정
- 홈 섹션별 부분 실패 복원력, 실시간(SSE) 홈 시세 구독
- 내 정보 메뉴에서의 심화 통계/분석

## 오픈 리스크

- `StockClient`/`OrderClient` public화는 두 기존 모듈의 공개 표면을 넓힌다. 대안(HomeFeature 자체 데이터 계층)은 DTO/매핑 중복이 커 채택하지 않음.
- `StockDetailFeature.State`/`init`가 internal이면 노출 필요 — 구현 첫 단계에서 확인.
