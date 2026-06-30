import ComposableArchitecture
import CoreDesignSystem
import SwiftUI

public struct OrderSheetView: View {
    private let store: StoreOf<OrderSheetFeature>

    public init(store: StoreOf<OrderSheetFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(store.stockName) · \(store.stockCode)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.tumoInk)

                        Text("\(store.currentPrice.formatted())원")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.tumoBody)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Result or Input
                    if let result = store.result {
                        ResultSection(result: result, mode: store.mode)
                            .padding(.horizontal, 20)

                        Button {
                            store.send(.closeTapped)
                        } label: {
                            Text("확인")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.tumoOnPrimary)
                        .background(Color.tumoBlue)
                        .clipShape(Capsule())
                        .padding(.horizontal, 20)
                    } else {
                        InputSection(store: store)
                            .padding(.horizontal, 20)

                        if let errorMessage = store.errorMessage {
                            MessageBanner(message: errorMessage, style: .error)
                                .padding(.horizontal, 20)
                        }

                        SubmitButton(
                            mode: store.mode,
                            isSubmitting: store.isSubmitting
                        ) {
                            store.send(.submitTapped)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

private struct InputSection: View {
    let store: StoreOf<OrderSheetFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quantity TextField
            TumoTextField(
                title: "주문 수량",
                placeholder: "예: 10",
                text: Binding(
                    get: { store.quantityText },
                    set: { store.send(.quantityChanged($0)) }
                )
            )
            .keyboardType(.numberPad)

            // Max button (only for sell)
            if store.mode == .sell {
                Button {
                    store.send(.maxTapped)
                } label: {
                    Text("보유 \(store.ownedQuantity)주 · 최대")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.tumoBlue)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }

            // Estimated amount
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("예상 금액")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Spacer(minLength: 16)

                Text("\(store.estimatedAmount.formatted())원")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.tumoCanvas)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.tumoHairline, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

private struct ResultSection: View {
    let result: Order
    let mode: OrderSheetFeature.Mode

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("체결 결과")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)

                Text("\(result.stockName) · \(result.stockCode)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoBody)
            }

            VStack(spacing: 0) {
                OrderInfoRow(title: "주문 유형", value: result.orderType)
                OrderInfoRow(title: "체결 수량", value: "\(result.quantity.formatted())주")
                OrderInfoRow(title: "체결가", value: "\(result.executedPrice.formatted())원")
                OrderInfoRow(title: "총 체결 금액", value: "\(result.totalAmount.formatted())원")

                // Realized profit (only for sell)
                if mode == .sell, let realizedProfit = result.realizedProfit {
                    let isProfit = realizedProfit >= 0
                    OrderInfoRow(
                        title: "실현손익",
                        value: "\((isProfit ? "+" : ""))\(realizedProfit.formatted())원",
                        valueColor: isProfit ? Color.tumoUp : Color.tumoDown
                    )
                }

                OrderInfoRow(
                    title: "주문 후 현금",
                    value: "\(result.cashBalance.formatted())원",
                    showsDivider: false
                )
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

private struct SubmitButton: View {
    let mode: OrderSheetFeature.Mode
    let isSubmitting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                }

                Text(isSubmitting ? "주문 중" : mode.actionTitle)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.tumoOnPrimary)
        .background(buttonBackgroundColor)
        .clipShape(Capsule())
        .disabled(isSubmitting)
    }

    private var buttonBackgroundColor: Color {
        if isSubmitting {
            return mode == .buy ? Color.tumoUpDisabled : Color.tumoDownDisabled
        }
        return mode == .buy ? Color.tumoUp : Color.tumoDown
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

private struct OrderInfoRow: View {
    let title: String
    let value: String
    var valueColor: Color?
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
                    .foregroundStyle(valueColor ?? Color.tumoInk)
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
    // Disabled variants
    static let tumoUpDisabled = Color(red: 240.0 / 255.0, green: 68.0 / 255.0, blue: 82.0 / 255.0).opacity(0.5)
    static let tumoDownDisabled = Color(red: 49.0 / 255.0, green: 130.0 / 255.0, blue: 246.0 / 255.0).opacity(0.5)

    // Error (dedicated red, not tumoDown which is blue)
    static let tumoError = Color(red: 207.0 / 255.0, green: 32.0 / 255.0, blue: 47.0 / 255.0)

    // Supporting colors (not in CoreDesignSystem)
    static let tumoCard = Color.white
    static let tumoOnPrimary = Color.white
}

#Preview("Buy") {
    OrderSheetView(
        store: Store(
            initialState: OrderSheetFeature.State(
                stockCode: "005930",
                stockName: "삼성전자",
                currentPrice: 75_000,
                mode: .buy,
                ownedQuantity: 0,
                quantityText: ""
            )
        ) {
            OrderSheetFeature()
        }
    )
}

#Preview("Sell with Result") {
    OrderSheetView(
        store: Store(
            initialState: OrderSheetFeature.State(
                stockCode: "005930",
                stockName: "삼성전자",
                currentPrice: 75_000,
                mode: .sell,
                ownedQuantity: 10,
                quantityText: "5",
                isSubmitting: false,
                result: Order(
                    orderId: 1,
                    stockCode: "005930",
                    stockName: "삼성전자",
                    orderType: "SELL",
                    quantity: 5,
                    executedPrice: 76_000,
                    totalAmount: 380_000,
                    realizedProfit: 5_000,
                    cashBalance: 9_250_000,
                    executedAt: "2026-05-13T17:20:00"
                )
            )
        ) {
            OrderSheetFeature()
        }
    )
}
