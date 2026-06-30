# iOS 주식 매수/매도/주문내역 설계

## Context

백엔드(Tumo)에 매수/매도/주문내역 API가 준비됨:
- `POST /api/v1/orders` — body `{stockCode, quantity, orderType: "BUY"|"SELL"}`, 응답에 `cashBalance` + `realizedProfit`(매도). 시장가 즉시 체결. JWT 필요.
- `GET /api/v1/orders?page&size` — 사용자 주문내역(전역, 최신순, slice 페이지네이션). JWT 필요.

iOS(`Tumo-iOS`, SwiftUI + TCA, Tuist 모듈)에는 **매수만** 구현돼 있음(`OrderFeature` 모듈의 독립 `OrderView` — 종목코드 수동 입력형). 매도·주문내역 미구현. 이 작업은 매수를 종목 상세 흐름으로 통합하고, 매도와 주문내역을 추가한다.

## 확정된 결정 (사용자 승인)

1. **진입점**: 종목 상세(StockDetail) 하단 **매수/매도 바** → 해당 종목 고정 **주문 시트(수량만 입력)**. 기존 '주문' 탭은 **주문내역**으로 전환.
2. **체결 흐름**: 수량 입력 → 버튼 탭 → **즉시 체결 + 결과 표시** (별도 확인 단계 없음).
3. **모듈 구조 (A안)**: 매수·매도·주문내역 **모두 `OrderFeature`에 구현**. `StockFeature`·`App`이 `import OrderFeature`로 사용.

## 아키텍처 (모듈 의존)

```
OrderFeature  (자급자족: 데이터계층 + 주문시트 + 주문내역)
   └─ 의존: TumoNetwork, CoreModels, CoreDesignSystem  (기존 그대로, StockFeature 의존 X)
StockFeature  ──import──▶ OrderFeature   (상세 하단 바 → 주문 시트)
App(MainView) ──import──▶ OrderFeature   ('주문' 탭 = 주문내역 화면)
```

- 순환 방지: 주문 시트는 `Stock` 엔티티가 아니라 **원시값**(stockCode·stockName·currentPrice·ownedQuantity)을 입력받는다.

## 데이터 계층 (OrderFeature 확장)

기존 5계층(API → DataSource → Repository → Usecase → Client) 패턴 그대로 확장.

- **OrderAPI** (`Sources/Data/API/OrderAPI.swift`): 케이스 추가
  - `sell(stockCode, quantity)` → `POST /api/v1/orders`, body `orderType:"SELL"`
  - `orderHistory(page, size)` → `GET /api/v1/orders` (query)
  - 모두 `authorizedProvider`(JWT). 매수와 동일 베이스 URL.
- **DTO** (`Sources/Data/DTO/`)
  - `OrderResponseDTO`에 `realizedProfit: Int?` 추가
  - 신규 `OrderHistoryItemDTO`(orderId·stockCode·stockName·orderType·quantity·executedPrice·totalAmount·realizedProfit?·executedAt) + `OrderPageDTO`(orders·page·size·hasNext)
- **Domain 엔티티** (`Sources/Domain/Entity/`)
  - `Order`에 `realizedProfit: Int?` 추가
  - 신규 `OrderHistoryItem`, `OrderPage`(items·page·hasNext)
- **DataSource / Repository / Usecase**: `sell`, `orderHistory(page,size)` 메서드 추가. 신규 `SellStockUsecase`, `FetchOrderHistoryUsecase`.
- **주문 컨텍스트(시트 표시용)**: 시트가 가용현금/보유수량을 보여주기 위해 `OrderClient.orderContext(stockCode)` 추가 — `GET /api/v1/portfolio`(JWT) 호출해 **현금잔고 + 해당 종목 보유수량**만 추출. (PortfolioFeature 직접 의존 대신 OrderFeature가 자체 호출해 결합도 낮춤.)
- **OrderClient** (`Sources/Data/Dependency/OrderClient.swift`) 최종 형태(@Sendable 클로저):
  - `buy(stockCode, quantity) -> Order` *(기존)*
  - `sell(stockCode, quantity) -> Order`
  - `history(page, size) -> OrderPage`
  - `orderContext(stockCode) -> OrderContext`(cashBalance, ownedQuantity)
  - `OrderAssembly.live()`에서 배선.

## 화면 / 컴포넌트

### 1. 하단 주문 바 (StockFeature — StockDetail)
- `StockDetailView` 하단에 sticky 바: `매수`(tumoUp 빨강 계열) / `매도`(tumoDown 파랑 계열) 버튼.
- 매도 버튼은 **보유수량 0이면 비활성**. → StockDetail이 진입 시 보유정보 로드(이미 MY주식 탭에서 로드하므로 재사용; 없으면 onAppear에서 로드).
- 탭 시 `OrderSheetFeature`를 `@Presents`로 시트 표시. 원시값(stockCode·stockName·currentPrice·mode·ownedQuantity) 전달.

### 2. OrderSheetFeature (OrderFeature — 신규 Reducer + View)
- State: 종목 고정 정보, `mode: .buy/.sell`, `quantityText`, `isSubmitting`, `errorMessage?`, `result: Order?`, `orderContext?`(cash/owned).
- onAppear: `orderClient.orderContext(stockCode)`로 가용현금/보유수량 로드.
- 본문: 수량 입력(텍스트+스테퍼), **예상금액 = 현재가 × 수량**, 매수=가용현금 표시 / 매도=보유수량 + **'최대' 버튼**.
- 제출: `매수`/`매도` 버튼 → `orderClient.buy/sell` → 성공 시 **결과 영역**(체결가·수량·총액·주문후잔고, 매도 시 **실현손익** 이익=빨강/손실=파랑) → 닫기. 닫을 때 StockDetail에 **delegate 액션**(보유/잔고 갱신 신호) 전달 → MY주식 탭 새로고침.
- 버튼 스타일·텍스트필드: 기존 `OrderView`의 tumoBlue/Capsule/TumoTextField 패턴 재사용.

### 3. OrderHistory (OrderFeature — 신규 Reducer + View, '주문' 탭)
- `App/MainView`의 `.orders` 탭 콘텐츠를 `OrderView()` → `OrderHistoryView()`로 교체.
- 전역 주문내역 최신순, slice **무한스크롤**(onAppear 첫 페이지, 마지막 행 도달 시 `hasNext`면 다음 페이지 append).
- 행: 종목명 · BUY/SELL 배지 · 수량 · 체결가 · 총액 · 실현손익(매도) · 체결시각. 빈/에러 상태는 기존 `MessageState` 재사용.
- 기존 수동입력 매수 `OrderView`/매수 전용 `OrderFeature` 리듀서는 **은퇴**(매수는 상세 시트로 일원화).

## 데이터 흐름

- **매수/매도**: OrderSheet → `orderClient.buy/sell` → `authorizedProvider`(JWT) → `POST /api/v1/orders` → 결과 표시 → delegate로 StockDetail 보유/잔고 갱신.
- **주문내역**: OrderHistory.onAppear/scroll → `orderClient.history(page,size)` → `GET /api/v1/orders` → append, `hasNext`로 다음 페이지.
- **시트 컨텍스트**: OrderSheet.onAppear → `orderClient.orderContext` → `GET /api/v1/portfolio` → cash/owned.

## 에러 처리

- 백엔드 `ErrorResponse{code,message}` 디코드(기존 `NetworkError`/`ErrorResponse` 활용) → 시트 내 **인라인 에러**.
- 매핑: `INSUFFICIENT_HOLDING`(보유 부족) · `INSUFFICIENT_CASH`(현금 부족) · `STOCK_PRICE_UNAVAILABLE`(현재가 조회 불가) → 사용자 메시지.
- 클라이언트 검증: 수량 1 이상 정수, 매도 시 보유수량 초과 입력 방지(서버도 검증하지만 UX상 사전 차단).

## 테스트

- TCA `TestStore` (기존 XCTest 컨벤션, `orderClient` 목 주입):
  - `OrderSheetFeature`: 매수/매도 성공(결과 상태), 실패(에러 메시지), 수량 검증, '최대' 버튼, 컨텍스트 로드.
  - `OrderHistoryFeature`: 첫 페이지 로드, 무한스크롤 append, `hasNext=false`에서 정지, 에러 상태.
  - DTO→엔티티 매핑(특히 `realizedProfit` nil/값).

## 범위 / Out-of-scope

- **포함**: 매수(상세 통합) + 매도 + 주문내역.
- **제외**: 포트폴리오 탭 구현(매도 보유수량은 상세/portfolio 데이터 활용). 백엔드가 전역 내역만 지원 → 종목별 내역 필터 제외. 지정가/예약 주문 제외(시장가만).

## 리스크 / 오픈 이슈

- `orderContext`가 `GET /api/v1/portfolio`를 재사용 → 포트폴리오 응답 형태 확인 필요(현금·보유 추출). PortfolioFeature와 중복 호출 가능성은 허용(단순성 우선).
- 베이스 URL이 `http://localhost:8080` 하드코딩(기존 패턴) — 배포 전 환경 분리 별도 과제.
- 동시성/낙관적 락은 **백엔드** 별도 과제(이 iOS 작업과 무관).
