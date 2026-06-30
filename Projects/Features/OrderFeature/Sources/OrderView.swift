import ComposableArchitecture
import CoreDesignSystem
import SwiftUI

public struct OrderView: View {
    private let store: StoreOf<OrderFeature>

    public init(
        store: StoreOf<OrderFeature> = Store(initialState: OrderFeature.State()) {
            OrderFeature()
        }
    ) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    OrderForm(store: store)

                    if let errorMessage = store.errorMessage {
                        MessageBanner(message: errorMessage, style: .error)
                    }

                    if let order = store.order {
                        OrderResultCard(order: order)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("주문")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OrderForm: View {
    let store: StoreOf<OrderFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("주문 정보")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tumoInk)

            TumoTextField(
                title: "종목 코드",
                placeholder: "예: 005930",
                text: Binding(
                    get: { store.stockCode },
                    set: { store.send(.stockCodeChanged($0)) }
                )
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()

            TumoTextField(
                title: "주문 수량",
                placeholder: "예: 10",
                text: Binding(
                    get: { store.quantity },
                    set: { store.send(.quantityChanged($0)) }
                )
            )
            .keyboardType(.numberPad)

            Button {
                store.send(.buyButtonTapped)
            } label: {
                HStack(spacing: 8) {
                    if store.isLoading {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    }

                    Text(store.isLoading ? "주문 중" : "매수")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.tumoOnPrimary)
            .background(store.isLoading ? Color.tumoBlueDisabled : Color.tumoBlue)
            .clipShape(Capsule())
            .disabled(store.isLoading)
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.tumoCard)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.tumoHairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TumoTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.tumoInk)

            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.tumoInk)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.tumoCanvas)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.tumoHairline, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct MessageBanner: View {
    enum Style {
        case error
    }

    let message: String
    let style: Style

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(foregroundColor.opacity(0.18), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var foregroundColor: Color {
        switch style {
        case .error:
            Color.tumoError
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .error:
            Color.tumoError.opacity(0.06)
        }
    }
}

private struct OrderResultCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("체결 결과")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)

                Text("\(order.stockName) · \(order.stockCode)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoBody)
            }

            VStack(spacing: 0) {
                OrderInfoRow(title: "주문 유형", value: order.orderType)
                OrderInfoRow(title: "체결 수량", value: "\(order.quantity.formatted())주")
                OrderInfoRow(title: "체결가", value: "\(order.executedPrice.formatted())원")
                OrderInfoRow(title: "총 체결 금액", value: "\(order.totalAmount.formatted())원")
                OrderInfoRow(title: "주문 후 현금", value: "\(order.cashBalance.formatted())원")
                OrderInfoRow(title: "체결 시각", value: order.executedAt, showsDivider: false)
            }
        }
        .padding(20)
        .background(Color.tumoCard)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.tumoHairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct OrderInfoRow: View {
    let title: String
    let value: String
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Spacer(minLength: 16)

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)

            if showsDivider {
                Rectangle()
                    .fill(Color.tumoHairlineSoft)
                    .frame(height: 1)
            }
        }
    }
}

private extension Color {
    static let tumoBlueDisabled = Color(red: 168.0 / 255.0, green: 184.0 / 255.0, blue: 204.0 / 255.0)
    static let tumoError = Color(red: 207.0 / 255.0, green: 32.0 / 255.0, blue: 47.0 / 255.0)
    static let tumoCard = Color.white
    static let tumoOnPrimary = Color.white
}

#Preview {
    NavigationStack {
        OrderView(
            store: Store(
                initialState: OrderFeature.State(
                    stockCode: "005930",
                    quantity: "10",
                    order: Order(
                        orderId: 1,
                        stockCode: "005930",
                        stockName: "삼성전자",
                        orderType: "BUY",
                        quantity: 10,
                        executedPrice: 75_000,
                        totalAmount: 750_000,
                        realizedProfit: nil,
                        cashBalance: 9_250_000,
                        executedAt: "2026-05-13T17:20:00"
                    )
                )
            ) {
                OrderFeature()
            }
        )
    }
}
