import ComposableArchitecture
import CoreDesignSystem
import Foundation
import SwiftUI

/// 종목 상세 화면. 헤더(실시간 현재가) + 차트/호가/MY주식 탭으로 구성한다.
public struct StockDetailView: View {
    private let store: StoreOf<StockDetailFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<StockDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)
                    .frame(width: 36, height: 36, alignment: .leading)
            }
            .buttonStyle(.plain)

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

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
        case .chart:
            ChartPlaceholder()

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

// MARK: - Chart

private struct ChartPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Color.tumoMutedSoft)

            Text("차트는 준비 중입니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tumoBody)

            Text("시세 차트 API 연동 후 제공될 예정입니다.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - Order Book

private struct OrderBookContent: View {
    let orderBook: StockOrderBook?
    let basePrice: Int

    var body: some View {
        if let orderBook, !orderBook.askLevels.isEmpty || !orderBook.bidLevels.isEmpty {
            ScrollView {
                OrderBookLadder(orderBook: orderBook, basePrice: basePrice)
                    .padding(.top, 4)
            }
        } else {
            VStack(spacing: 10) {
                ProgressView()
                    .tint(Color.tumoMuted)

                Text("호가를 기다리는 중입니다")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Text("장 운영 시간이 아니면 호가가 없을 수 있어요.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tumoMutedSoft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
    }
}

private struct OrderBookLadder: View {
    let orderBook: StockOrderBook
    let basePrice: Int

    var body: some View {
        VStack(spacing: 0) {
            // 매도호가: 높은 가격이 위로 오도록 역순 정렬한다.
            ForEach(Array(orderBook.askLevels.reversed().enumerated()), id: \.offset) { _, level in
                OrderBookRow(level: level, side: .ask, basePrice: basePrice, maxVolume: maxVolume)
            }

            // 매수호가: 최우선(높은 가격)이 위로 온다.
            ForEach(Array(orderBook.bidLevels.enumerated()), id: \.offset) { _, level in
                OrderBookRow(level: level, side: .bid, basePrice: basePrice, maxVolume: maxVolume)
            }
        }
    }

    private var maxVolume: Int {
        let volumes = orderBook.askLevels.map(\.volume) + orderBook.bidLevels.map(\.volume)
        return max(1, volumes.max() ?? 1)
    }
}

private enum OrderBookSide {
    case ask
    case bid
}

private struct OrderBookRow: View {
    let level: StockOrderBookLevel
    let side: OrderBookSide
    let basePrice: Int
    let maxVolume: Int

    var body: some View {
        HStack(spacing: 0) {
            volumeCell(showsVolume: side == .ask, anchor: .trailing, color: Color.tumoUp)
            priceCell
            volumeCell(showsVolume: side == .bid, anchor: .leading, color: Color.tumoDown)
        }
        .frame(height: 42)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.tumoHairlineSoft)
                .frame(height: 1)
        }
    }

    private var priceCell: some View {
        Text(level.price.formatted())
            .font(.system(size: 15, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(priceColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(side == .ask ? Color.tumoUp.opacity(0.05) : Color.tumoDown.opacity(0.05))
    }

    private func volumeCell(showsVolume: Bool, anchor: Alignment, color: Color) -> some View {
        GeometryReader { geometry in
            if showsVolume {
                ZStack(alignment: anchor) {
                    color.opacity(0.12)
                        .frame(width: geometry.size.width * volumeFraction)

                    Text(level.volume.formatted())
                        .font(.system(size: 13, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoBody)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, alignment: anchor)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var volumeFraction: CGFloat {
        min(1, CGFloat(level.volume) / CGFloat(maxVolume))
    }

    private var priceColor: Color {
        if level.price > basePrice {
            return Color.tumoUp
        }

        if level.price < basePrice {
            return Color.tumoDown
        }

        return Color.tumoInk
    }
}

// MARK: - MY Stock

private struct MyStockContent: View {
    let holding: StockHolding?
    let isLoaded: Bool
    let errorMessage: String?

    var body: some View {
        if let errorMessage, !isLoaded {
            MessageState(
                systemImage: "exclamationmark.triangle",
                title: errorMessage,
                subtitle: "MY주식 탭을 다시 누르면 재시도합니다."
            )
        } else if !isLoaded {
            VStack {
                ProgressView()
                    .tint(Color.tumoMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let holding {
            HoldingCard(holding: holding)
        } else {
            MessageState(
                systemImage: "tray",
                title: "보유하고 있지 않습니다",
                subtitle: "이 종목을 보유하면 평가손익이 표시됩니다."
            )
        }
    }
}

private struct HoldingCard: View {
    let holding: StockHolding

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("평가손익")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text(signedAmountText)
                        .font(.system(size: 26, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(profitColor)

                    Text(signedRateText)
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(profitColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.tumoSurfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 0) {
                    HoldingMetricRow(title: "보유수량", value: "\(holding.quantity.formatted())주")
                    metricHairline
                    HoldingMetricRow(title: "평균단가", value: "\(holding.averagePrice.formatted())원")
                    metricHairline
                    HoldingMetricRow(title: "현재가", value: "\(holding.currentPrice.formatted())원")
                    metricHairline
                    HoldingMetricRow(title: "평가금액", value: "\(holding.evaluationAmount.formatted())원")
                }
                .padding(.horizontal, 4)
            }
            .padding(20)
        }
    }

    private var metricHairline: some View {
        Rectangle()
            .fill(Color.tumoHairlineSoft)
            .frame(height: 1)
    }

    private var signedAmountText: String {
        let sign = holding.profitAmount > 0 ? "+" : ""
        return "\(sign)\(holding.profitAmount.formatted())원"
    }

    private var signedRateText: String {
        let sign = holding.profitRate > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", holding.profitRate))%"
    }

    private var profitColor: Color {
        if holding.profitAmount > 0 {
            return Color.tumoUp
        }

        if holding.profitAmount < 0 {
            return Color.tumoDown
        }

        return Color.tumoInk
    }
}

private struct HoldingMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoMuted)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.tumoInk)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Shared

private struct MarketBadge: View {
    let market: String

    var body: some View {
        Text(market)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.tumoBlue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.tumoBlue.opacity(0.08), in: Capsule())
    }
}

private struct MessageState: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.tumoMutedSoft)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tumoBody)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
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
