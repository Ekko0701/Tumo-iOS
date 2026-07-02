# iOS 포트폴리오 탭 설계

## Context

iOS(`Tumo-iOS`, SwiftUI + TCA + Tuist)의 `포트폴리오` 탭은 현재 placeholder다(`MainView`의 `.portfolio`). 백엔드 `GET /api/v1/portfolio`(JWT)는 이미 포트폴리오에 필요한 데이터를 모두 제공한다:

```
PortfolioResponse: cashBalance, totalStockValue, totalAsset, profitAmount, profitRate,
                   holdings[]{ stockCode, stockName, quantity, averagePrice, currentPrice,
                               evaluationAmount, profitAmount, profitRate }
```

iOS엔 `PortfolioAPI`(StockFeature 내, `GET /api/v1/portfolio`)와 `PortfolioResponseDTO`가 있으나 **현재 holdings만 디코딩**하고(현금·총자산 무시), 종목 1개용 `fetchHolding`만 노출한다. 전체 포트폴리오를 반환하는 경로는 없다. 이 작업은 매수/매도로 만든 결과(보유·평가손익·현금)를 실제로 보는 화면을 추가해 **트레이딩 루프를 완성**한다.

## 확정된 결정 (사용자 승인)

1. **데이터 신선도**: 화면 진입 시 `GET /api/v1/portfolio` **스냅샷** 조회 + **당겨서 새로고침**(실시간 SSE 아님). 백엔드가 평가액·총액·손익을 이미 계산.
2. **행 탭**: 보유 종목 행 탭 → 해당 종목 **StockDetail로 이동**.
3. **모듈 배치 (A안)**: 포트폴리오 탭을 **StockFeature에 구현**. `PortfolioAPI`와 `StockDetail`이 이미 StockFeature에 있어 엔드포인트 중복·교차 모듈 의존이 없고, 상세 이동이 같은 모듈 내 push로 간단.

## 아키텍처

```
StockFeature
 ├─ Data: PortfolioResponseDTO(확장) ← 기존 PortfolioAPI(GET /api/v1/portfolio)
 ├─ Domain: Portfolio(신규 엔티티), FetchPortfolioUsecase(신규)
 ├─ Dependency: StockClient.fetchPortfolio() 추가, Assembly 배선
 └─ Presentation/Portfolio: PortfolioFeature(@Reducer) + PortfolioView
App(MainView) .portfolio 탭 → PortfolioView()
```
- 빈 `PortfolioFeature` 모듈은 이번 범위에서 사용하지 않음(추후 정리 후보).

## 데이터 계층 (StockFeature 확장)

- **엔티티** `Portfolio`(신규): `cashBalance, totalStockValue, totalAsset, profitAmount, profitRate, holdings: [StockHolding]` — 모두 값타입/`Sendable`. `StockHolding`(기존)을 재사용.
- **DTO** `PortfolioResponseDTO` 확장: 기존 `holdings` 유지 + `cashBalance, totalStockValue, totalAsset, profitAmount, profitRate` 디코딩 추가. `toPortfolio()` 매핑 신설. (기존 `fetchHolding`이 쓰는 holdings 파싱은 그대로 동작.)
- **Usecase** `FetchPortfolioUsecase`(+Impl) → `StockRepository.fetchPortfolio() -> Portfolio` → `StockDataSource.portfolio() -> PortfolioResponseDTO`.
- **Client** `StockClient.fetchPortfolio: @Sendable () async throws -> Portfolio` 추가, `StockClient.live(...)`·`StockAssembly.live()` 배선.

## 화면 / 컴포넌트 (StockFeature 내 `Presentation/Portfolio/`)

- **PortfolioFeature** (`@Reducer`, `@ObservableState`): State(`portfolio: Portfolio?`, `isLoading`, `errorMessage`, 네비게이션 상태). Actions(`onAppear`, `refresh`, `portfolioLoaded(Portfolio)`, `loadFailed`, `holdingTapped(stockCode:)`, `stockLoaded(Stock)`/네비게이션).
- **PortfolioView**:
  - 상단 **요약 카드**: `총자산`(크게) · `평가손익 금액 + 수익률%`(이익 `Color.tumoUp` 빨강 / 손실 `Color.tumoDown` 파랑) · `현금` · `보유주식평가액`.
  - **보유 종목 리스트**: 행 = 종목명 · 수량 · 평단 · 현재가 · 평가금액 · 평가손익(+%) 색상. 탭 → `.holdingTapped(stockCode)`.
  - **당겨서 새로고침**(`.refreshable`) + `.onAppear` 최초 로드.
  - 빈 상태(holdings 비었을 때) / 에러 상태 → 기존 `MessageState`(또는 동등) 재사용.
  - 색상은 캐노니컬 CoreDesignSystem 토큰 사용(`tumoUp`/`tumoDown` private 재정의 금지).
- **행 탭 → 상세 이동**: `.holdingTapped` → `stockClient.fetchStock(stockCode)`로 `Stock` 조회 → `StockDetailView` push. StockFeature의 **기존 `StockView → StockDetail` 네비게이션 패턴을 그대로 미러링**(StackState/path 또는 `@Presents`). 포트폴리오 탭 자체 NavigationStack 내에서 push.

## App 연결

- `Projects/App/Sources/MainView.swift`의 `.portfolio` 탭 콘텐츠를 placeholder → `PortfolioView()`로 교체(`import StockFeature`는 이미 있음).

## 데이터 흐름

- 진입/새로고침: `PortfolioFeature.onAppear`/`.refresh` → `stockClient.fetchPortfolio()` → `GET /api/v1/portfolio`(JWT) → `Portfolio` → State 갱신.
- 행 탭: `.holdingTapped(code)` → `stockClient.fetchStock(code)` → `Stock` → StockDetail push.

## 에러 / 빈 상태

- 로드 실패 → 에러 메시지 + 재시도(당겨서 새로고침 또는 재시도 버튼).
- 보유 0 → "보유 종목이 없습니다" 안내(요약 카드의 현금/총자산은 표시).

## 테스트

- TCA `TestStore`(기존 XCTest 컨벤션, `stockClient` 목 주입):
  - `onAppear` → 포트폴리오 로드 성공(요약+목록 반영).
  - 빈 목록 로드(현금만 있는 상태).
  - 로드 실패 → errorMessage.
  - `refresh` 재조회.
  - `holdingTapped` → `fetchStock` 호출 후 상세 네비게이션 트리거.
- DTO→엔티티 매핑(현금/총자산/손익 + holdings) 검증.

## 범위 / Out-of-scope

- **포함**: 포트폴리오 요약 + 보유 목록(스냅샷·당겨서 새로고침), 행 탭 → 상세 이동.
- **제외**: 실시간(SSE) 평가 갱신, 자산 추이 차트/기간 수익률, 종목별 정렬/필터. 매수/매도는 기존 StockDetail 흐름 재사용.

## 리스크 / 오픈 이슈

- 상세 이동 시 `StockDetailFeature.State`는 `Stock`을 요구 → `fetchStock`로 조회 후 push(추가 1회 호출). 대안(보유 정보로 부분 Stock seed)은 헤더 필드 결손 → `fetchStock` 우선.
- baseURL `http://localhost:8080` 하드코딩(기존 패턴) — 배포 전 환경 분리 별도 과제.
- `PortfolioResponseDTO` 확장이 기존 `fetchHolding` 경로에 영향 없어야 함(holdings 파싱 유지).
