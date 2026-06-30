import ComposableArchitecture
import CoreDesignSystem
import SwiftUI

public struct OrderHistoryView: View {
    private let store: StoreOf<OrderHistoryFeature>

    public init(store: StoreOf<OrderHistoryFeature> = Store(initialState: OrderHistoryFeature.State()) {
        OrderHistoryFeature()
    }) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            if store.items.isEmpty && !store.isLoading && store.errorMessage == nil {
                EmptyStateView()
            } else if let errorMessage = store.errorMessage {
                ErrorStateView(message: errorMessage)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            OrderHistoryRow(item: item)

                            Rectangle()
                                .fill(Color.tumoHairline)
                                .frame(height: 1)
                        }

                        if store.hasNext {
                            HStack {
                                Spacer()
                                if store.isLoading {
                                    ProgressView()
                                        .tint(Color.tumoBody)
                                }
                                Spacer()
                            }
                            .frame(height: 60)
                            .onAppear {
                                store.send(.loadNextPage)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("주문 내역")
        .onAppear {
            store.send(.onAppear)
        }
    }
}

private struct OrderHistoryRow: View {
    let item: OrderHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: 종목명 + BUY/SELL 배지
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.stockName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)

                    Text(item.stockCode)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)
                }

                Spacer()

                Badge(orderType: item.orderType)
            }

            // 수량·체결가·총액
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("수량")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(item.quantity.formatted())주")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("체결가")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(item.executedPrice.formatted())원")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("총액")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(item.totalAmount.formatted())원")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)
                }

                Spacer()
            }

            // Realized profit (SELL만 표시)
            if item.orderType == "SELL", let realizedProfit = item.realizedProfit {
                let isProfit = realizedProfit >= 0
                HStack(alignment: .center, spacing: 8) {
                    Text("실현손익")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\((isProfit ? "+" : ""))\(realizedProfit.formatted())원")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isProfit ? Color.tumoUp : Color.tumoDown)
                }
            }

            // 체결시각
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Text(formatExecutedAt(item.executedAt))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func formatExecutedAt(_ dateString: String) -> String {
        // dateString format: "2026-05-13T17:20:00"
        let components = dateString.split(separator: "T")
        guard components.count == 2 else { return dateString }

        let timePart = String(components[1]).split(separator: ":").prefix(2).joined(separator: ":")
        return timePart
    }
}

private struct Badge: View {
    let orderType: String

    var body: some View {
        Text(orderType == "BUY" ? "매수" : "매도")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.tumoOnPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(orderType == "BUY" ? Color.tumoUp : Color.tumoDown)
            .clipShape(Capsule())
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.tumoMuted)

            Text("주문 내역이 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tumoInk)

            Text("주문을 체결하면 여기에 표시됩니다")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.tumoError)

            Text("오류 발생")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tumoInk)

            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

private extension Color {
    static let tumoError = Color(red: 207.0 / 255.0, green: 32.0 / 255.0, blue: 47.0 / 255.0)
    static let tumoOnPrimary = Color.white
}

#Preview("Order History") {
    NavigationStack {
        OrderHistoryView(
            store: Store(
                initialState: OrderHistoryFeature.State(
                    items: [
                        OrderHistoryItem(
                            orderId: 1,
                            stockCode: "005930",
                            stockName: "삼성전자",
                            orderType: "BUY",
                            quantity: 10,
                            executedPrice: 75_000,
                            totalAmount: 750_000,
                            realizedProfit: nil,
                            executedAt: "2026-05-13T17:20:00"
                        ),
                        OrderHistoryItem(
                            orderId: 2,
                            stockCode: "005930",
                            stockName: "삼성전자",
                            orderType: "SELL",
                            quantity: 5,
                            executedPrice: 76_000,
                            totalAmount: 380_000,
                            realizedProfit: 5_000,
                            executedAt: "2026-05-14T09:15:30"
                        ),
                        OrderHistoryItem(
                            orderId: 3,
                            stockCode: "000660",
                            stockName: "SK하이닉스",
                            orderType: "SELL",
                            quantity: 3,
                            executedPrice: 165_000,
                            totalAmount: 495_000,
                            realizedProfit: -15_000,
                            executedAt: "2026-05-14T10:45:00"
                        )
                    ]
                )
            ) {
                OrderHistoryFeature()
            }
        )
    }
}

#Preview("Empty State") {
    NavigationStack {
        OrderHistoryView(
            store: Store(
                initialState: OrderHistoryFeature.State(items: [])
            ) {
                OrderHistoryFeature()
            }
        )
    }
}

#Preview("Error State") {
    NavigationStack {
        OrderHistoryView(
            store: Store(
                initialState: OrderHistoryFeature.State(
                    items: [],
                    errorMessage: "주문 내역을 불러오지 못했습니다."
                )
            ) {
                OrderHistoryFeature()
            }
        )
    }
}
