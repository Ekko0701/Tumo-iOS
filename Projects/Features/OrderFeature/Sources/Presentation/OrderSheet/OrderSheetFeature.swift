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
