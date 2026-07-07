import ComposableArchitecture
import CoreDesignSystem
import Foundation
import OrderFeature
import SwiftUI

/// 종목 상세 화면. 헤더(실시간 현재가) + 차트/호가/MY주식 탭으로 구성한다.
public struct StockDetailView: View {
    private let store: StoreOf<StockDetailFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<StockDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        @Bindable var store = store

        return ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                StockDetailSegment(selected: store.selectedTab) { tab in
                    store.send(.tabSelected(tab), animation: .easeInOut(duration: 0.2))
                }

                Rectangle()
                    .fill(Color.tumoHairlineSoft)
                    .frame(height: 1)

                tabContent

                Spacer()

                orderBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
        .sheet(item: $store.scope(state: \.orderSheet, action: \.orderSheet)) { sheetStore in
            OrderSheetView(store: sheetStore)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Header

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

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(store.stock.stockName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.tumoInk)
                        .lineLimit(1)

                    MarketBadge(market: store.stock.market)
                }

                Text(store.stock.stockCode)
                    .font(.system(size: 13, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.stock.currentPrice.formatted())원")
                    .font(.system(size: 30, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoInk)

                Text(changeText)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(changeColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var changeText: String {
        guard let changePrice = store.stock.changePrice else {
            return "-"
        }

        let arrow = priceDirection == .up ? "▲" : (priceDirection == .down ? "▼" : "")
        let amount = abs(changePrice).formatted()
        let rate = store.stock.changeRate.map { decimal -> String in
            let value = NSDecimalNumber(decimal: decimal).doubleValue
            let sign = value > 0 ? "+" : ""
            return " (\(sign)\(String(format: "%.2f", value))%)"
        } ?? ""

        return "\(arrow) \(amount)\(rate)"
    }

    private var changeColor: Color {
        switch priceDirection {
        case .up:
            Color.tumoUp
        case .down:
            Color.tumoDown
        case .flat:
            Color.tumoMuted
        }
    }

    private var priceDirection: PriceDirection {
        let change = store.stock.changePrice ?? 0

        if change > 0 {
            return .up
        }

        if change < 0 {
            return .down
        }

        return .flat
    }

    // MARK: - Order Bar

    private var orderBar: some View {
        HStack(spacing: 12) {
            Button {
                store.send(.buyTapped)
            } label: {
                Text("매수")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.tumoUp, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Button {
                store.send(.sellTapped)
            } label: {
                Text("매도")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.tumoDown, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled((store.holding?.quantity ?? 0) == 0)
            .opacity((store.holding?.quantity ?? 0) == 0 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.tumoCanvas)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
        case .chart:
            ChartContent(
                candles: store.candles,
                selectedInterval: store.selectedInterval,
                isLoading: store.isCandleLoading,
                errorMessage: store.candleErrorMessage,
                onSelectInterval: { store.send(.intervalSelected($0)) },
                onRetry: { store.send(.loadCandles) },
                onReachedLeadingEdge: { store.send(.loadOlderCandles) }
            )

        case .orderBook:
            OrderBookContent(orderBook: store.orderBook, basePrice: store.stock.currentPrice)

        case .myStock:
            MyStockContent(
                holding: store.holding,
                isLoaded: store.isHoldingLoaded,
                errorMessage: store.holdingErrorMessage
            )
        }
    }
}

private enum PriceDirection {
    case up
    case down
    case flat
}

// MARK: - Segment

private struct StockDetailSegment: View {
    let selected: StockDetailFeature.Tab
    let onSelect: (StockDetailFeature.Tab) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(StockDetailFeature.Tab.allCases) { tab in
                let isSelected = tab == selected

                Button {
                    onSelect(tab)
                } label: {
                    Text(tab.title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.tumoInk : Color.tumoMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? Color.tumoSurfaceStrong : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

#Preview("호가") {
    StockDetailView(
        store: Store(
            initialState: StockDetailFeature.State(
                stock: Stock(
                    stockCode: "005930",
                    stockName: "삼성전자",
                    market: "KOSPI",
                    currentPrice: 75_000,
                    changePrice: 1_000,
                    changeRate: Decimal(string: "1.35"),
                    tradeVolume: 1_234_567,
                    tradeAmount: 92_592_592_500,
                    priceChangedAt: "2026-05-13T15:30:00"
                ),
                selectedTab: .orderBook,
                orderBook: StockOrderBook(
                    stockCode: "005930",
                    askLevels: [
                        StockOrderBookLevel(price: 75_100, volume: 1_200),
                        StockOrderBookLevel(price: 75_200, volume: 3_400),
                        StockOrderBookLevel(price: 75_300, volume: 800)
                    ],
                    bidLevels: [
                        StockOrderBookLevel(price: 75_000, volume: 2_100),
                        StockOrderBookLevel(price: 74_900, volume: 1_500),
                        StockOrderBookLevel(price: 74_800, volume: 4_200)
                    ],
                    orderBookChangedAt: "2026-05-13T15:30:00"
                )
            )
        ) {
            StockDetailFeature()
        }
    )
}
