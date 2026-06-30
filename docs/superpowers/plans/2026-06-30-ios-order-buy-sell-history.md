# iOS 주식 매수/매도/주문내역 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 종목 상세 화면에서 매수/매도를 즉시 체결하고, '주문' 탭에서 주문내역을 조회하는 기능을 추가한다.

**Architecture:** 매수/매도/주문내역의 데이터·화면을 모두 `OrderFeature` 모듈에 구현하고, `StockFeature`(상세 하단 바 → 주문 시트)와 `App`('주문' 탭 = 주문내역)이 `import OrderFeature`로 사용한다. 순환 방지를 위해 주문 시트는 `Stock` 엔티티가 아니라 원시값(stockCode·stockName·currentPrice·ownedQuantity)을 입력받는다. 기존 매수 5계층(API→DataSource→Repository→Usecase→Client) 패턴을 그대로 미러링한다.

**Tech Stack:** Swift 6, SwiftUI, The Composable Architecture(TCA), Tuist 모듈, 자체 CoreNetwork(`Provider`/`TargetType`), JWT는 `TumoProviderFactory.live.authorizedProvider()`로 주입. 테스트는 XCTest + TCA `TestStore`.

## Global Constraints

- 백엔드 주문 API: `POST /api/v1/orders` body `{stockCode, quantity, orderType: "BUY"|"SELL"}`, 응답에 `cashBalance`, 매도 시 `realizedProfit`(매수는 null). `GET /api/v1/orders?page&size` → `{orders:[...], page, size, hasNext}`. 모두 JWT 필요.
- 베이스 URL은 기존 패턴 그대로 `http://localhost:8080` (환경 분리는 범위 외).
- 색상: 상승/이익 = `Color.tumoUp`(빨강), 하락/손실 = `Color.tumoDown`(파랑). 토스 관습. OrderFeature 내부는 `OrderView.swift`가 쓰는 private `Color` 확장 패턴을 따른다.
- 코딩 규칙: `let` 우선, 값타입/`Sendable`, 프로토콜+구현 분리(기존 Clean Arch), `@Reducer`/`@ObservableState`, `@Dependency` 클로저 클라이언트.
- 시장가 즉시 체결만 지원(지정가/예약 없음). 수량은 1 이상 정수.
- **스펙 대비 보정**: 주문 시트는 `ownedQuantity`만 원시값으로 받는다. 매수 가용현금 표시는 v1에서 생략(현금 조회 API가 iOS에 없음 → 서버의 `INSUFFICIENT_CASH`를 인라인 에러로 처리). 따라서 `orderContext`/portfolio 호출은 만들지 않는다. (백엔드는 동시성에 `@Version` 낙관적 락 적용됨 → 충돌 시 409 `ORDER_CONFLICT` 반환 가능. 시트 에러 매핑에서 함께 고려.)

---

## File Structure

**OrderFeature (수정/생성)**
- `Sources/Data/API/OrderAPI.swift` — 수정: `.sell`, `.orderHistory` 케이스 추가
- `Sources/Data/DTO/OrderResponseDTO.swift` — 수정: `realizedProfit: Int?` 추가
- `Sources/Data/DTO/OrderHistoryResponseDTO.swift` — 생성: `OrderHistoryItemDTO`, `OrderPageDTO`
- `Sources/Domain/Entity/Order.swift` — 수정: `realizedProfit: Int?` 추가
- `Sources/Domain/Entity/OrderHistory.swift` — 생성: `OrderHistoryItem`, `OrderPage`
- `Sources/Data/DataSource/Interface/OrderDataSource.swift` + `Impl/OrderDataSourceImpl.swift` — 수정: `sell`, `orderHistory`
- `Sources/Domain/Repository/Interface/OrderRepository.swift` + `Sources/Data/Repository/Impl/OrderRepositoryImpl.swift` — 수정: `sell`, `history`
- `Sources/Domain/Usecase/Interface/SellStockUsecase.swift` + `Impl/SellStockUsecaseImpl.swift` — 생성
- `Sources/Domain/Usecase/Interface/FetchOrderHistoryUsecase.swift` + `Impl/FetchOrderHistoryUsecaseImpl.swift` — 생성
- `Sources/Data/Dependency/OrderClient.swift` — 수정: `sell`, `history` 추가
- `Sources/Data/Dependency/OrderAssembly.swift` — 수정: 새 유스케이스 배선
- `Sources/Presentation/OrderSheet/OrderSheetFeature.swift` + `OrderSheetView.swift` — 생성
- `Sources/Presentation/OrderHistory/OrderHistoryFeature.swift` + `OrderHistoryView.swift` — 생성
- `Sources/OrderView.swift`, `Sources/OrderFeature.swift` — 삭제(은퇴): 매수 전용 수동입력 화면
- `Tests/Sources/OrderSheetFeatureTests.swift`, `OrderHistoryFeatureTests.swift` — 생성

**StockFeature (수정)**
- `Project.swift` — 수정: `.module(.orderFeature)` 의존성 추가
- `Sources/Presentation/StockDetail/Feature/StockDetailFeature.swift` — 수정: 진입 시 보유 로드, 주문 시트 presentation, 매수/매도 액션, delegate 처리
- `Sources/Presentation/StockDetail/View/StockDetailView.swift` — 수정: 하단 매수/매도 바 + 시트 표시

**App (수정)**
- `Sources/MainView.swift` — 수정: `.orders` 탭 `OrderView()` → `OrderHistoryView()`

---

## Task 1: 데이터 계층 — 엔티티 + DTO에 realizedProfit / 주문내역 타입 추가

**Files:**
- Modify: `Projects/Features/OrderFeature/Sources/Domain/Entity/Order.swift`
- Modify: `Projects/Features/OrderFeature/Sources/Data/DTO/OrderResponseDTO.swift`
- Create: `Projects/Features/OrderFeature/Sources/Domain/Entity/OrderHistory.swift`
- Create: `Projects/Features/OrderFeature/Sources/Data/DTO/OrderHistoryResponseDTO.swift`

**Interfaces:**
- Produces: `Order.realizedProfit: Int?`; `OrderHistoryItem`(orderId,stockCode,stockName,orderType,quantity,executedPrice,totalAmount,realizedProfit:Int?,executedAt); `OrderPage`(items:[OrderHistoryItem], page:Int, hasNext:Bool); `OrderHistoryItemDTO`, `OrderPageDTO`.

- [ ] **Step 1: `Order`에 realizedProfit 추가**

`Order.swift`의 프로퍼티에 `public let realizedProfit: Int?` 추가, init 파라미터에 `realizedProfit: Int?` 추가(기본값 없이 명시) 및 `self.realizedProfit = realizedProfit` 대입. (init 호출부는 Task 2의 `toEntity`와 `OrderView.swift` Preview인데, `OrderView.swift`는 Task 8에서 삭제되므로 무시.)

- [ ] **Step 2: `OrderResponseDTO`에 realizedProfit 추가**

```swift
struct OrderResponseDTO: Decodable, Sendable {
    let orderId: Int
    let stockCode: String
    let stockName: String
    let orderType: String
    let quantity: Int
    let executedPrice: Int
    let totalAmount: Int
    let realizedProfit: Int?   // 매수는 null
    let cashBalance: Int
    let executedAt: String
}
```

- [ ] **Step 3: 주문내역 엔티티 생성** (`OrderHistory.swift`)

```swift
/// 주문내역 1건.
public struct OrderHistoryItem: Equatable, Sendable, Identifiable {
    public var id: Int { orderId }
    public let orderId: Int
    public let stockCode: String
    public let stockName: String
    public let orderType: String   // "BUY" | "SELL"
    public let quantity: Int
    public let executedPrice: Int
    public let totalAmount: Int
    public let realizedProfit: Int?
    public let executedAt: String

    public init(orderId: Int, stockCode: String, stockName: String, orderType: String, quantity: Int, executedPrice: Int, totalAmount: Int, realizedProfit: Int?, executedAt: String) {
        self.orderId = orderId
        self.stockCode = stockCode
        self.stockName = stockName
        self.orderType = orderType
        self.quantity = quantity
        self.executedPrice = executedPrice
        self.totalAmount = totalAmount
        self.realizedProfit = realizedProfit
        self.executedAt = executedAt
    }
}

/// 주문내역 한 페이지(slice).
public struct OrderPage: Equatable, Sendable {
    public let items: [OrderHistoryItem]
    public let page: Int
    public let hasNext: Bool

    public init(items: [OrderHistoryItem], page: Int, hasNext: Bool) {
        self.items = items
        self.page = page
        self.hasNext = hasNext
    }
}
```

- [ ] **Step 4: 주문내역 DTO 생성** (`OrderHistoryResponseDTO.swift`)

```swift
struct OrderHistoryItemDTO: Decodable, Sendable {
    let orderId: Int
    let stockCode: String
    let stockName: String
    let orderType: String
    let quantity: Int
    let executedPrice: Int
    let totalAmount: Int
    let realizedProfit: Int?
    let executedAt: String
}

struct OrderPageDTO: Decodable, Sendable {
    let orders: [OrderHistoryItemDTO]
    let page: Int
    let size: Int
    let hasNext: Bool
}
```

- [ ] **Step 5: Commit**

```bash
git add Projects/Features/OrderFeature/Sources/Domain/Entity Projects/Features/OrderFeature/Sources/Data/DTO
git commit -m "feat(order): add realizedProfit and order-history entities/DTOs"
```

---

## Task 2: 데이터 계층 — API/DataSource/Repository에 sell·history 추가

**Files:**
- Modify: `Sources/Data/API/OrderAPI.swift`
- Modify: `Sources/Data/DataSource/Interface/OrderDataSource.swift`, `Sources/Data/DataSource/Impl/OrderDataSourceImpl.swift`
- Modify: `Sources/Domain/Repository/Interface/OrderRepository.swift`, `Sources/Data/Repository/Impl/OrderRepositoryImpl.swift`

**Interfaces:**
- Consumes: `OrderResponseDTO`, `OrderPageDTO`, `Order`, `OrderPage` (Task 1).
- Produces: `OrderRepository.sell(stockCode,quantity) -> Order`, `OrderRepository.history(page,size) -> OrderPage`; DataSource 동일 시그니처(DTO 반환).

- [ ] **Step 1: `OrderAPI`에 케이스 추가** (기존 `.buy` 유지)

```swift
enum OrderAPI: TargetType {
    case buy(stockCode: String, quantity: Int)
    case sell(stockCode: String, quantity: Int)
    case orderHistory(page: Int, size: Int)

    var baseURL: URL { URL(string: "http://localhost:8080")! }

    var path: String { "/api/v1/orders" }

    var method: HTTPMethod {
        switch self {
        case .buy, .sell: .post
        case .orderHistory: .get
        }
    }

    var task: Task {
        switch self {
        case .buy(let stockCode, let quantity):
            return .requestParameters(["stockCode": stockCode, "quantity": quantity, "orderType": "BUY"], encoding: .json)
        case .sell(let stockCode, let quantity):
            return .requestParameters(["stockCode": stockCode, "quantity": quantity, "orderType": "SELL"], encoding: .json)
        case .orderHistory(let page, let size):
            return .requestParameters(["page": page, "size": size], encoding: .url)
        }
    }
}
```
> 확인: `.url` 인코딩 케이스명이 `Projects/Core/CoreNetwork/Sources/Target/Task.swift`와 일치하는지 보고, 다르면 그 이름을 쓴다.

- [ ] **Step 2: `OrderDataSource` 프로토콜 확장**
```swift
protocol OrderDataSource: Sendable {
    func buy(stockCode: String, quantity: Int) async throws -> OrderResponseDTO
    func sell(stockCode: String, quantity: Int) async throws -> OrderResponseDTO
    func orderHistory(page: Int, size: Int) async throws -> OrderPageDTO
}
```

- [ ] **Step 3: `OrderDataSourceImpl` 구현 추가** (기존 `buy` 아래)
```swift
func sell(stockCode: String, quantity: Int) async throws -> OrderResponseDTO {
    try await provider.request(.sell(stockCode: stockCode, quantity: quantity), as: OrderResponseDTO.self)
}

func orderHistory(page: Int, size: Int) async throws -> OrderPageDTO {
    try await provider.request(.orderHistory(page: page, size: size), as: OrderPageDTO.self)
}
```

- [ ] **Step 4: `OrderRepository` 프로토콜 확장**
```swift
protocol OrderRepository: Sendable {
    func buy(stockCode: String, quantity: Int) async throws -> Order
    func sell(stockCode: String, quantity: Int) async throws -> Order
    func history(page: Int, size: Int) async throws -> OrderPage
}
```

- [ ] **Step 5: `OrderRepositoryImpl` 구현 + 매핑 추가**

`buy` 아래에 추가하고, `toEntity()`에 `realizedProfit: realizedProfit` 추가, page/item 매핑 추가:
```swift
func sell(stockCode: String, quantity: Int) async throws -> Order {
    let dto = try await orderDataSource.sell(stockCode: stockCode, quantity: quantity)
    return dto.toEntity()
}

func history(page: Int, size: Int) async throws -> OrderPage {
    let dto = try await orderDataSource.orderHistory(page: page, size: size)
    return dto.toEntity()
}
```
```swift
private extension OrderResponseDTO {
    func toEntity() -> Order {
        Order(orderId: orderId, stockCode: stockCode, stockName: stockName, orderType: orderType,
              quantity: quantity, executedPrice: executedPrice, totalAmount: totalAmount,
              realizedProfit: realizedProfit, cashBalance: cashBalance, executedAt: executedAt)
    }
}

private extension OrderPageDTO {
    func toEntity() -> OrderPage {
        OrderPage(items: orders.map { $0.toEntity() }, page: page, hasNext: hasNext)
    }
}

private extension OrderHistoryItemDTO {
    func toEntity() -> OrderHistoryItem {
        OrderHistoryItem(orderId: orderId, stockCode: stockCode, stockName: stockName, orderType: orderType,
                         quantity: quantity, executedPrice: executedPrice, totalAmount: totalAmount,
                         realizedProfit: realizedProfit, executedAt: executedAt)
    }
}
```

- [ ] **Step 6: Commit**
```bash
git add Projects/Features/OrderFeature/Sources/Data Projects/Features/OrderFeature/Sources/Domain/Repository
git commit -m "feat(order): add sell and order-history to API/datasource/repository"
```

---

## Task 3: 데이터 계층 — Usecase + OrderClient + Assembly

**Files:**
- Create: `Sources/Domain/Usecase/Interface/SellStockUsecase.swift`, `Impl/SellStockUsecaseImpl.swift`
- Create: `Sources/Domain/Usecase/Interface/FetchOrderHistoryUsecase.swift`, `Impl/FetchOrderHistoryUsecaseImpl.swift`
- Modify: `Sources/Data/Dependency/OrderClient.swift`, `Sources/Data/Dependency/OrderAssembly.swift`

**Interfaces:**
- Consumes: `OrderRepository.sell/history` (Task 2).
- Produces: `OrderClient.sell(stockCode,quantity) -> Order`, `OrderClient.history(page,size) -> OrderPage` (테스트에서 목 주입).

- [ ] **Step 1: SellStockUsecase 생성** (buy 미러)
```swift
// Interface/SellStockUsecase.swift
protocol SellStockUsecase: Sendable {
    func execute(stockCode: String, quantity: Int) async throws -> Order
}
```
```swift
// Impl/SellStockUsecaseImpl.swift
struct SellStockUsecaseImpl: SellStockUsecase {
    private let orderRepository: any OrderRepository
    init(orderRepository: any OrderRepository) { self.orderRepository = orderRepository }
    func execute(stockCode: String, quantity: Int) async throws -> Order {
        try await orderRepository.sell(stockCode: stockCode, quantity: quantity)
    }
}
```

- [ ] **Step 2: FetchOrderHistoryUsecase 생성**
```swift
// Interface/FetchOrderHistoryUsecase.swift
protocol FetchOrderHistoryUsecase: Sendable {
    func execute(page: Int, size: Int) async throws -> OrderPage
}
```
```swift
// Impl/FetchOrderHistoryUsecaseImpl.swift
struct FetchOrderHistoryUsecaseImpl: FetchOrderHistoryUsecase {
    private let orderRepository: any OrderRepository
    init(orderRepository: any OrderRepository) { self.orderRepository = orderRepository }
    func execute(page: Int, size: Int) async throws -> OrderPage {
        try await orderRepository.history(page: page, size: size)
    }
}
```

- [ ] **Step 3: `OrderClient`에 sell/history 추가**
```swift
struct OrderClient: Sendable {
    var buy: @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order
    var sell: @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order
    var history: @Sendable (_ page: Int, _ size: Int) async throws -> OrderPage

    init(
        buy: @escaping @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order,
        sell: @escaping @Sendable (_ stockCode: String, _ quantity: Int) async throws -> Order,
        history: @escaping @Sendable (_ page: Int, _ size: Int) async throws -> OrderPage
    ) {
        self.buy = buy
        self.sell = sell
        self.history = history
    }
}

extension OrderClient {
    static func live(
        buyStockUsecase: any BuyStockUsecase,
        sellStockUsecase: any SellStockUsecase,
        fetchOrderHistoryUsecase: any FetchOrderHistoryUsecase
    ) -> OrderClient {
        OrderClient(
            buy: { try await buyStockUsecase.execute(stockCode: $0, quantity: $1) },
            sell: { try await sellStockUsecase.execute(stockCode: $0, quantity: $1) },
            history: { try await fetchOrderHistoryUsecase.execute(page: $0, size: $1) }
        )
    }
}
```
(아래 `OrderClientKey`/`DependencyValues` 확장은 그대로 둔다.)

- [ ] **Step 4: `OrderAssembly` 배선 갱신**
```swift
enum OrderAssembly {
    static func live() -> OrderClient {
        let provider: Provider<OrderAPI> = TumoProviderFactory.live.authorizedProvider()
        let orderDataSource = OrderDataSourceImpl(provider: provider)
        let orderRepository = OrderRepositoryImpl(orderDataSource: orderDataSource)
        return OrderClient.live(
            buyStockUsecase: BuyStockUsecaseImpl(orderRepository: orderRepository),
            sellStockUsecase: SellStockUsecaseImpl(orderRepository: orderRepository),
            fetchOrderHistoryUsecase: FetchOrderHistoryUsecaseImpl(orderRepository: orderRepository)
        )
    }
}
```

- [ ] **Step 5: 빌드 확인 + Commit**

Run: `tuist generate` 후 OrderFeature 빌드(`xcodebuild -scheme OrderFeature build`). Expected: 성공.
```bash
git add Projects/Features/OrderFeature/Sources/Domain/Usecase Projects/Features/OrderFeature/Sources/Data/Dependency
git commit -m "feat(order): wire sell/history usecases into OrderClient"
```

---

## Task 4: OrderSheetFeature (Reducer) + 테스트

**Files:**
- Create: `Sources/Presentation/OrderSheet/OrderSheetFeature.swift`
- Test: `Tests/Sources/OrderSheetFeatureTests.swift`

**Interfaces:**
- Consumes: `OrderClient.buy/sell` (Task 3), `Order` (Task 1).
- Produces: `OrderSheetFeature` with `enum Mode { case buy, case sell }`, `State`(stockCode,stockName,currentPrice,mode,ownedQuantity,quantityText,isSubmitting,result:Order?,errorMessage:String?), `Action.delegate(.orderCompleted(Order))`. 상위(StockDetail)는 `delegate(.orderCompleted)`만 소비.

- [ ] **Step 1: 실패 테스트 작성** (`OrderSheetFeatureTests.swift`)
```swift
import ComposableArchitecture
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
}
```

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -scheme OrderFeature`. Expected: 컴파일 실패(OrderSheetFeature 미정의).

- [ ] **Step 3: `OrderSheetFeature` 구현**
```swift
import ComposableArchitecture

@Reducer
public struct OrderSheetFeature {
    @Dependency(\.orderClient) private var orderClient

    public init() {}

    public enum Mode: Equatable, Sendable {
        case buy
        case sell
        var actionTitle: String { self == .buy ? "매수" : "매도" }
    }

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: String { stockCode + (mode == .buy ? "-buy" : "-sell") }
        public let stockCode: String
        public let stockName: String
        public let currentPrice: Int
        public let mode: Mode
        public let ownedQuantity: Int
        public var quantityText: String
        public var isSubmitting: Bool
        public var result: Order?
        public var errorMessage: String?

        public init(stockCode: String, stockName: String, currentPrice: Int, mode: Mode,
                    ownedQuantity: Int, quantityText: String = "", isSubmitting: Bool = false,
                    result: Order? = nil, errorMessage: String? = nil) {
            self.stockCode = stockCode
            self.stockName = stockName
            self.currentPrice = currentPrice
            self.mode = mode
            self.ownedQuantity = ownedQuantity
            self.quantityText = quantityText
            self.isSubmitting = isSubmitting
            self.result = result
            self.errorMessage = errorMessage
        }

        /// 예상 체결 금액(현재가 × 수량).
        public var estimatedAmount: Int { (Int(quantityText) ?? 0) * currentPrice }
    }

    public enum Action: Equatable {
        case quantityChanged(String)
        case maxTapped
        case submitTapped
        case orderCompleted(Order)
        case orderFailed(String)
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case orderCompleted(Order)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .quantityChanged(text):
                state.quantityText = text.filter(\.isNumber)
                state.errorMessage = nil
                return .none

            case .maxTapped:
                state.quantityText = String(state.ownedQuantity)
                return .none

            case .submitTapped:
                guard let quantity = Int(state.quantityText), quantity > 0 else {
                    state.errorMessage = "주문 수량을 확인해주세요."
                    return .none
                }
                if state.mode == .sell, quantity > state.ownedQuantity {
                    state.errorMessage = "보유 수량을 초과했습니다."
                    return .none
                }

                state.isSubmitting = true
                state.errorMessage = nil

                let stockCode = state.stockCode
                let mode = state.mode
                let orderClient = orderClient
                return .run { send in
                    do {
                        let order = mode == .buy
                            ? try await orderClient.buy(stockCode, quantity)
                            : try await orderClient.sell(stockCode, quantity)
                        await send(.orderCompleted(order))
                    } catch {
                        await send(.orderFailed(Self.message(for: error)))
                    }
                }

            case let .orderCompleted(order):
                state.isSubmitting = false
                state.result = order
                state.errorMessage = nil
                return .send(.delegate(.orderCompleted(order)))

            case let .orderFailed(message):
                state.isSubmitting = false
                state.errorMessage = message
                return .none

            case .closeTapped, .delegate:
                return .none
            }
        }
    }

    /// 백엔드 에러를 사용자 메시지로 변환.
    private static func message(for error: Error) -> String {
        // 구현 시 Projects/Core/CoreNetwork/Sources/Error/NetworkError.swift 를 읽어
        // 서버 ErrorResponse(code/message)를 꺼낼 수 있으면 그 message를 사용
        // (INSUFFICIENT_HOLDING / INSUFFICIENT_CASH / STOCK_PRICE_UNAVAILABLE / ORDER_CONFLICT),
        // 불가하면 아래 기본 문구로 폴백한다.
        return "주문에 실패했습니다."
    }
}
```
> 구현자 메모: `message(for:)`를 서버 message 추출로 보강하면, 위 `test_failure_*`의 기대 문구도 함께 맞춘다.

- [ ] **Step 4: 테스트 통과 확인** — Run: `xcodebuild test -scheme OrderFeature`. Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Projects/Features/OrderFeature/Sources/Presentation/OrderSheet Projects/Features/OrderFeature/Tests/Sources/OrderSheetFeatureTests.swift
git commit -m "feat(order): add OrderSheetFeature reducer with tests"
```

---

## Task 5: OrderSheetView

**Files:**
- Create: `Sources/Presentation/OrderSheet/OrderSheetView.swift`

**Interfaces:**
- Consumes: `OrderSheetFeature` (Task 4).

- [ ] **Step 1: 뷰 구현**

`StoreOf<OrderSheetFeature>`를 받는 `public struct OrderSheetView: View`. 구성:
- 헤더: `state.stockName · state.stockCode`, 현재가.
- 결과 분기: `if let result = store.result` → 결과 카드(`OrderView.swift`의 `OrderResultCard` 스타일 재사용: 체결가·수량·총액·주문후잔고, 매도면 실현손익 행 — 이익 `Color.tumoUp`/손실 `Color.tumoDown`) + "확인" 버튼(`store.send(.closeTapped)`).
- 입력 분기(결과 없을 때): 수량 TextField(`quantityText` 바인딩 → `.quantityChanged`), 매도면 "보유 \(ownedQuantity)주 · 최대" 버튼(`.maxTapped`), 예상금액 `store.estimatedAmount`, 에러(`store.errorMessage` → 배너), 제출 버튼(라벨 `store.mode.actionTitle`, 매수=`tumoUp` 톤/매도=`tumoDown` 톤, `isSubmitting`이면 비활성+ProgressView → `.submitTapped`).
- 버튼/텍스트필드/배너/색상 확장은 `OrderView.swift`의 패턴을 그대로 가져와 사용(이 파일에 private 컴포넌트로 복제).

> 뷰는 자동 테스트 대상 아님(스냅샷 미도입). 컴파일·프리뷰로 확인.

- [ ] **Step 2: 빌드/프리뷰 확인 + Commit**
```bash
git add Projects/Features/OrderFeature/Sources/Presentation/OrderSheet/OrderSheetView.swift
git commit -m "feat(order): add OrderSheetView"
```

---

## Task 6: OrderHistoryFeature (Reducer, 페이지네이션) + 테스트

**Files:**
- Create: `Sources/Presentation/OrderHistory/OrderHistoryFeature.swift`
- Test: `Tests/Sources/OrderHistoryFeatureTests.swift`

**Interfaces:**
- Consumes: `OrderClient.history` (Task 3), `OrderPage`/`OrderHistoryItem` (Task 1).
- Produces: `OrderHistoryFeature` with State(items,page,hasNext,isLoading,errorMessage), Actions(onAppear, loadNextPage, pageLoaded(OrderPage), loadFailed). page size 상수 30.

- [ ] **Step 1: 실패 테스트 작성**
```swift
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
}
```

- [ ] **Step 2: 테스트 실패 확인** — Run: `xcodebuild test -scheme OrderFeature`. Expected: 컴파일 실패.

- [ ] **Step 3: `OrderHistoryFeature` 구현**
```swift
import ComposableArchitecture

@Reducer
public struct OrderHistoryFeature {
    @Dependency(\.orderClient) private var orderClient

    public init() {}

    private static let pageSize = 30

    @ObservableState
    public struct State: Equatable {
        public var items: [OrderHistoryItem]
        public var page: Int
        public var hasNext: Bool
        public var isLoading: Bool
        public var errorMessage: String?

        public init(items: [OrderHistoryItem] = [], page: Int = 0, hasNext: Bool = true,
                    isLoading: Bool = false, errorMessage: String? = nil) {
            self.items = items
            self.page = page
            self.hasNext = hasNext
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Equatable {
        case onAppear
        case loadNextPage
        case pageLoaded(OrderPage)
        case loadFailed
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.items.isEmpty, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return loadPage(0)

            case .loadNextPage:
                guard state.hasNext, !state.isLoading else { return .none }
                state.isLoading = true
                return loadPage(state.page + 1)

            case let .pageLoaded(page):
                state.isLoading = false
                state.errorMessage = nil
                if page.page == 0 {
                    state.items = page.items
                } else {
                    state.items += page.items
                }
                state.page = page.page
                state.hasNext = page.hasNext
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "주문 내역을 불러오지 못했습니다."
                return .none
            }
        }
    }

    private func loadPage(_ page: Int) -> Effect<Action> {
        let orderClient = orderClient
        return .run { send in
            do {
                let result = try await orderClient.history(page, Self.pageSize)
                await send(.pageLoaded(result))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
```

- [ ] **Step 4: 테스트 통과 확인** — Run: `xcodebuild test -scheme OrderFeature`. Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add Projects/Features/OrderFeature/Sources/Presentation/OrderHistory/OrderHistoryFeature.swift Projects/Features/OrderFeature/Tests/Sources/OrderHistoryFeatureTests.swift
git commit -m "feat(order): add OrderHistoryFeature reducer with pagination tests"
```

---

## Task 7: OrderHistoryView

**Files:**
- Create: `Sources/Presentation/OrderHistory/OrderHistoryView.swift`

**Interfaces:**
- Consumes: `OrderHistoryFeature` (Task 6).

- [ ] **Step 1: 뷰 구현**

`public struct OrderHistoryView: View`. 기본 store는 `Store(initialState: OrderHistoryFeature.State()) { OrderHistoryFeature() }` (App 탭에서 인자 없이 생성). 구성:
- `List`(또는 `ScrollView`+`LazyVStack`)로 `store.items` 렌더. 행: 종목명 + BUY/SELL 배지(매수 `tumoUp`/매도 `tumoDown` 톤) + 수량·체결가·총액, 매도면 실현손익(이익 `tumoUp`/손실 `tumoDown`), 체결시각.
- 마지막 행 `onAppear` → `store.send(.loadNextPage)` (무한스크롤).
- 빈 상태(`items.isEmpty && !isLoading && errorMessage == nil`)·에러 상태 표시(이 모듈에 동등 컴포넌트 복제).
- 첫 로딩 `.onAppear` → `store.send(.onAppear)`.
- `.navigationTitle("주문 내역")`.

- [ ] **Step 2: 빌드/프리뷰 확인 + Commit**
```bash
git add Projects/Features/OrderFeature/Sources/Presentation/OrderHistory/OrderHistoryView.swift
git commit -m "feat(order): add OrderHistoryView with infinite scroll"
```

---

## Task 8: 기존 매수 전용 화면 은퇴 + App '주문' 탭 교체

**Files:**
- Delete: `Projects/Features/OrderFeature/Sources/OrderView.swift`, `Projects/Features/OrderFeature/Sources/OrderFeature.swift`
- Modify: `Projects/App/Sources/MainView.swift`

**Interfaces:**
- Consumes: `OrderHistoryView` (Task 7).

- [ ] **Step 1: App 탭 콘텐츠 교체**

`MainView.swift`의 `MainTabContentView`에서:
```swift
case .orders:
    OrderHistoryView()
```
(`import OrderFeature`는 이미 있음.)

- [ ] **Step 2: 매수 전용 파일 삭제**
```bash
git rm Projects/Features/OrderFeature/Sources/OrderView.swift Projects/Features/OrderFeature/Sources/OrderFeature.swift
```
> `tuist generate` 후, 삭제된 매수 전용 `OrderFeature` 리듀서를 참조하는 곳이 없는지 빌드로 확인.

- [ ] **Step 3: 빌드 확인 + Commit**

Run: App 스킴 빌드. Expected: 성공.
```bash
git add Projects/App/Sources/MainView.swift
git commit -m "feat(order): replace orders tab with OrderHistoryView; retire manual buy screen"
```

---

## Task 9: StockFeature 통합 — OrderFeature 의존성 + StockDetail 하단 바·주문 시트

**Files:**
- Modify: `Projects/Features/StockFeature/Project.swift`
- Modify: `Projects/Features/StockFeature/Sources/Presentation/StockDetail/Feature/StockDetailFeature.swift`
- Modify: `Projects/Features/StockFeature/Sources/Presentation/StockDetail/View/StockDetailView.swift`

**Interfaces:**
- Consumes: `OrderSheetFeature`(State/Action/Mode, `delegate(.orderCompleted)`), `OrderSheetView` (Tasks 4,5). `state.holding?.quantity`(StockHolding) → ownedQuantity.

- [ ] **Step 1: 모듈 의존성 추가** (`StockFeature/Project.swift`의 `dependencies`에 추가)
```swift
.module(.orderFeature),
```

- [ ] **Step 2: StockDetailFeature — import + 진입 시 보유 로드**

`import OrderFeature` 추가. `.onAppear`가 항상 보유를 로드하도록 수정(하단 바 매도 활성/수량):
```swift
case .onAppear:
    return .merge(
        .send(.startPriceStream),
        state.isHoldingLoaded ? .none : .send(.loadHolding),
        effectOnEnter(tab: state.selectedTab, state: state)
    )
```

- [ ] **Step 3: StockDetailFeature — 주문 시트 presentation + 매수/매도 액션**

State에 추가:
```swift
@Presents public var orderSheet: OrderSheetFeature.State?
```
Action에 추가:
```swift
case buyTapped
case sellTapped
case orderSheet(PresentationAction<OrderSheetFeature.Action>)
```
body의 `Reduce` 뒤에 `.ifLet(\.$orderSheet, action: \.orderSheet) { OrderSheetFeature() }` 추가. 케이스 처리:
```swift
case .buyTapped:
    state.orderSheet = OrderSheetFeature.State(
        stockCode: state.stock.stockCode, stockName: state.stock.stockName,
        currentPrice: state.stock.currentPrice, mode: .buy, ownedQuantity: state.holding?.quantity ?? 0)
    return .none

case .sellTapped:
    state.orderSheet = OrderSheetFeature.State(
        stockCode: state.stock.stockCode, stockName: state.stock.stockName,
        currentPrice: state.stock.currentPrice, mode: .sell, ownedQuantity: state.holding?.quantity ?? 0)
    return .none

case .orderSheet(.presented(.delegate(.orderCompleted))):
    state.isHoldingLoaded = false
    return .send(.loadHolding)   // 체결 후 보유/하단 바 갱신

case .orderSheet:
    return .none
```

- [ ] **Step 4: StockDetailView — 하단 바 + 시트**

`StockDetailView`를 읽고 하단에 sticky 주문 바 추가:
- `매수` → `store.send(.buyTapped)` (`tumoUp` 톤), `매도` → `store.send(.sellTapped)` (`tumoDown` 톤). 매도는 `(store.holding?.quantity ?? 0) == 0`이면 `.disabled(true)`.
- 시트:
```swift
.sheet(item: $store.scope(state: \.orderSheet, action: \.orderSheet)) { sheetStore in
    OrderSheetView(store: sheetStore)
        .presentationDetents([.medium])
}
```

- [ ] **Step 5: 빌드 확인 + Commit**

Run: `tuist generate` 후 StockFeature + App 빌드. Expected: 성공(OrderFeature는 StockFeature 미참조 → 순환 없음).
```bash
git add Projects/Features/StockFeature/Project.swift Projects/Features/StockFeature/Sources/Presentation/StockDetail
git commit -m "feat(stock): add buy/sell bar and order sheet to stock detail"
```

---

## Task 10: 전체 검증

- [ ] **Step 1: 전체 테스트** — Run: `xcodebuild test -scheme OrderFeature`(+StockFeature 테스트 스킴 있으면). Expected: 신규 리듀서 테스트 포함 전부 PASS.
- [ ] **Step 2: 앱 수동 시나리오** (로그인 상태)
  - 종목 상세 진입 → 하단 매수/매도 바, 미보유 종목은 매도 비활성
  - 매수 시트: 수량 입력 → 매수 → 결과(체결가·총액·잔고) → 닫기 → MY주식 보유 반영
  - 매도 시트: '최대' → 매도 → 결과 실현손익(이익 빨강/손실 파랑) → 전량 매도 시 보유 0
  - 보유 초과 매도 입력 → "보유 수량을 초과했습니다." 인라인
  - '주문' 탭 → 주문내역 최신순, 스크롤 시 다음 페이지 로드
- [ ] **Step 3: 최종 커밋/푸시** (요청 시) — 브랜치 `feat/order-buy-sell-history` 푸시 후 PR.

---

## Self-Review (작성자 점검 결과)

- **스펙 커버리지**: 매수(상세 통합)=Task 4·5·9, 매도=Task 2·4·5·9, 주문내역=Task 6·7·8, 데이터계층=Task 1·2·3, 탭 전환·은퇴=Task 8. 전부 태스크 존재.
- **스펙 보정 반영**: `orderContext`/portfolio 호출 제거(현금 조회 API 부재). 매수 가용현금 표시 생략, 매도 보유수량은 StockDetail `holding.quantity`에서 원시값 전달. Global Constraints에 명시.
- **타입 일관성**: `OrderClient.buy/sell/history`, `Order.realizedProfit:Int?`, `OrderPage(items,page,hasNext)`, `OrderSheetFeature.Action.delegate(.orderCompleted(Order))`가 정의 태스크(1·3·4·6)와 소비 태스크(4·6·9)에서 일치.
- **구현자 확인 필요(메모로 표기)**: ① `Task.swift`의 url 인코딩 케이스명, ② `NetworkError`의 서버 message 추출 가능 여부(에러 매핑 보강 — `ORDER_CONFLICT` 포함), ③ `StockDetailView` 실제 구조에 맞춘 하단 바 삽입 위치.
```
