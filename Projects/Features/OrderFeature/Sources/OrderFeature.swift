//
//  OrderFeature.swift
//  OrderFeature
//
//  Created by Ekko on 5/24/26.
//

import ComposableArchitecture

@Reducer
public struct OrderFeature {
    @Dependency(\.orderClient) private var orderClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        /// 사용자가 주문하려는 종목 코드.
        public var stockCode: String = ""

        /// 사용자가 입력한 주문 수량 문자열.
        public var quantity: String = ""

        /// 매수 주문 요청이 진행 중인지 나타내는 로딩 상태.
        public var isLoading: Bool = false

        /// 매수 주문 성공 시 서버에서 내려온 주문 체결 결과.
        public var order: Order? = nil

        /// 입력 검증 실패 또는 주문 요청 실패 시 화면에 보여줄 오류 메시지.
        public var errorMessage: String? = nil

        public init(
            stockCode: String = "",
            quantity: String = "",
            isLoading: Bool = false,
            order: Order? = nil,
            errorMessage: String? = nil
        ) {
            self.stockCode = stockCode
            self.quantity = quantity
            self.isLoading = isLoading
            self.order = order
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Equatable {
        /// 종목 코드 입력값이 변경되었을 때 발생하는 액션.
        case stockCodeChanged(String)

        /// 주문 수량 입력값이 변경되었을 때 발생하는 액션.
        case quantityChanged(String)

        /// 매수 버튼을 눌러 주문을 요청할 때 발생하는 액션.
        case buyButtonTapped

        /// 매수 주문 요청이 성공해 주문 결과를 받았을 때 발생하는 액션.
        case orderPlaced(Order)

        /// 매수 주문 요청이 실패했을 때 발생하는 액션.
        case orderFailed(String)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .stockCodeChanged(stockCode):
                state.stockCode = stockCode
                state.errorMessage = nil
                return .none

            case let .quantityChanged(quantity):
                state.quantity = quantity
                state.errorMessage = nil
                return .none

            case .buyButtonTapped:
                guard !state.stockCode.isEmpty else {
                    state.errorMessage = "종목 코드를 입력해주세요."
                    return .none
                }

                guard let quantity = Int(state.quantity), quantity > 0 else {
                    state.errorMessage = "주문 수량을 확인해주세요."
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil
                state.order = nil

                let stockCode = state.stockCode
                let orderClient = orderClient

                return .run { send in
                    do {
                        let order = try await orderClient.buy(stockCode, quantity)
                        await send(.orderPlaced(order))
                    } catch {
                        await send(.orderFailed("주문에 실패했습니다."))
                    }
                }

            case let .orderPlaced(order):
                state.isLoading = false
                state.order = order
                state.errorMessage = nil
                return .none

            case let .orderFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }

}
