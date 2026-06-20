import ComposableArchitecture
import CoreDesignSystem
import Foundation
import SwiftUI

public struct StockView: View {
    private let store: StoreOf<StockFeature>

    public init(
        store: StoreOf<StockFeature> = Store(initialState: StockFeature.State()) {
            StockFeature()
        }
    ) {
        self.store = store
    }

    public var body: some View {
        @Bindable var store = store

        return ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    StockListHeader()

                    StockSortSegment(selected: store.sortOption) { option in
                        store.send(.sortOptionChanged(option), animation: .easeInOut(duration: 0.2))
                    }

                    content
                }
            }
            .refreshable {
                store.send(.refreshButtonTapped)
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
        .navigationDestination(
            item: $store.scope(state: \.detail, action: \.detail)
        ) { detailStore in
            StockDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.stocks.isEmpty {
            ForEach(0 ..< 8, id: \.self) { _ in
                StockSkeletonRow()
            }
        } else if let errorMessage = store.errorMessage, store.stocks.isEmpty {
            StockErrorState(message: errorMessage) {
                store.send(.refreshButtonTapped)
            }
        } else if store.isEmptyStateVisible {
            StockEmptyState()
        } else {
            let stocks = store.displayedStocks

            ForEach(Array(stocks.enumerated()), id: \.element.id) { index, stock in
                Button {
                    store.send(.stockTapped(stock))
                } label: {
                    StockRow(rank: index + 1, stock: stock, sortOption: store.sortOption)
                }
                .buttonStyle(.plain)

                if index < stocks.count - 1 {
                    Rectangle()
                        .fill(Color.tumoHairlineSoft)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

// MARK: - Header

private struct StockListHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("종목")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.tumoInk)

            Text("실시간 종목 랭킹 Top 30")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Sort Segment

private struct StockSortSegment: View {
    let selected: StockSortOption
    let onSelect: (StockSortOption) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StockSortOption.allCases) { option in
                    let isSelected = option == selected

                    Button {
                        onSelect(option)
                    } label: {
                        Text(option.title)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.tumoInk : Color.tumoMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.tumoSurfaceStrong : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Row

private struct StockRow: View {
    let rank: Int
    let stock: Stock
    let sortOption: StockSortOption

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.tumoMuted)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(stock.stockName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(stock.stockCode)
                        .font(.system(size: 13, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoMuted)

                    MarketBadge(market: stock.market)
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(stock.currentPrice.formatted())원")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoInk)

                Text(metricText)
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(metricColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var metricText: String {
        switch sortOption {
        case .tradeAmount:
            "거래대금 \(formattedAmount(stock.tradeAmount))"
        case .tradeVolume:
            "거래량 \(formattedVolume(stock.tradeVolume))"
        case .rising, .falling:
            formattedChangeRate(stock.changeRate)
        }
    }

    private var metricColor: Color {
        guard let changeRate = stock.changeRate else {
            return Color.tumoMuted
        }

        let value = NSDecimalNumber(decimal: changeRate).doubleValue

        if value > 0 {
            return Color.tumoUp
        }

        if value < 0 {
            return Color.tumoDown
        }

        return Color.tumoMuted
    }

    private func formattedAmount(_ amount: Int?) -> String {
        guard let amount else {
            return "-"
        }

        if amount >= 100_000_000 {
            return "\(amount / 100_000_000)억"
        }

        if amount >= 10_000 {
            return "\(amount / 10_000)만"
        }

        return amount.formatted()
    }

    private func formattedVolume(_ volume: Int?) -> String {
        guard let volume else {
            return "-"
        }

        return volume.formatted()
    }

    private func formattedChangeRate(_ changeRate: Decimal?) -> String {
        guard let changeRate else {
            return "등락률 -"
        }

        let value = NSDecimalNumber(decimal: changeRate).doubleValue
        let sign = value > 0 ? "+" : ""

        return "\(sign)\(String(format: "%.2f", value))%"
    }
}

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

// MARK: - States

private struct StockSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.tumoSurfaceStrong)
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.tumoSurfaceSoft)
                    .frame(width: 76, height: 12)
            }

            Spacer(minLength: 12)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.tumoSurfaceStrong)
                .frame(width: 64, height: 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct StockErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoBody)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("다시 시도")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.tumoBlue, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 96)
    }
}

private struct StockEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.tumoMutedSoft)

            Text("조회 가능한 종목이 없습니다.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 96)
    }
}

#Preview {
    StockView(
        store: Store(
            initialState: StockFeature.State(
                stocks: [
                    Stock(
                        stockCode: "005930",
                        stockName: "삼성전자",
                        market: "KOSPI",
                        currentPrice: 75_000,
                        changePrice: 100,
                        changeRate: Decimal(string: "0.13"),
                        tradeVolume: 1_234_567,
                        tradeAmount: 92_592_592_500,
                        priceChangedAt: "2026-05-13T15:30:00"
                    ),
                    Stock(
                        stockCode: "000660",
                        stockName: "SK하이닉스",
                        market: "KOSPI",
                        currentPrice: 180_000,
                        changePrice: -500,
                        changeRate: Decimal(string: "-0.28"),
                        tradeVolume: 987_654,
                        tradeAmount: 177_777_720_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    ),
                    Stock(
                        stockCode: "035420",
                        stockName: "NAVER",
                        market: "KOSPI",
                        currentPrice: 190_000,
                        changePrice: 2_500,
                        changeRate: Decimal(string: "1.33"),
                        tradeVolume: 456_789,
                        tradeAmount: 86_789_910_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    ),
                    Stock(
                        stockCode: "035720",
                        stockName: "카카오",
                        market: "KOSDAQ",
                        currentPrice: 55_000,
                        changePrice: -1_000,
                        changeRate: Decimal(string: "-1.79"),
                        tradeVolume: 765_432,
                        tradeAmount: 42_098_760_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    )
                ]
            )
        ) {
            StockFeature()
        }
    )
}
