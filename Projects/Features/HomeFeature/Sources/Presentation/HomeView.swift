import ComposableArchitecture
import CoreDesignSystem
import Foundation
import OrderFeature
import StockFeature
import SwiftUI

public struct HomeView: View {
    private let store: StoreOf<HomeFeature>

    public init(
        store: StoreOf<HomeFeature> = Store(initialState: HomeFeature.State()) {
            HomeFeature()
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
                    HomeHeader()
                    content
                }
            }
            .refreshable {
                store.send(.refresh)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            store.send(.onAppear)
        }
        .navigationDestination(
            item: $store.scope(state: \.stockDetail, action: \.stockDetail)
        ) { detailStore in
            StockDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.portfolio == nil {
            // Loading skeleton
            ForEach(0 ..< 5, id: \.self) { _ in
                HomeSkeletonRow()
            }
        } else if let errorMessage = store.errorMessage {
            // Error state
            HomeErrorState(message: errorMessage) {
                store.send(.refresh)
            }
        } else if let portfolio = store.portfolio {
            // Summary card
            HomeSummaryCard(portfolio: portfolio)

            // "급상승" section
            TopMoversSection(
                topMovers: store.topMovers,
                onStockTapped: { stock in
                    store.send(.stockTapped(stock))
                }
            )

            // "최근 주문" section
            RecentOrdersSection(recentOrders: store.recentOrders)
        }
    }
}

// MARK: - Header

struct HomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("홈")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.tumoInk)

            Text("나의 투자 현황")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Summary Card

struct HomeSummaryCard: View {
    let portfolio: Portfolio

    var body: some View {
        VStack(spacing: 16) {
            // 총자산
            VStack(alignment: .leading, spacing: 4) {
                Text("총자산")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Text("\(portfolio.totalAsset.formatted())원")
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 평가손익 and 보유현금
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("평가손익")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    HStack(spacing: 4) {
                        Text("\(portfolio.profitAmount.formatted())원")
                            .font(.system(size: 16, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(profitLossColor)

                        Text("(\(formatProfitRate(portfolio.profitRate))%)")
                            .font(.system(size: 14, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(profitLossColor)
                    }
                }

                Spacer()

                // 보유현금
                VStack(alignment: .leading, spacing: 4) {
                    Text("보유현금")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(portfolio.cashBalance.formatted())원")
                        .font(.system(size: 16, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoInk)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.tumoSurfaceStrong, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var profitLossColor: Color {
        portfolio.profitAmount >= 0 ? Color.tumoUp : Color.tumoDown
    }

    private func formatProfitRate(_ rate: Double) -> String {
        let sign = rate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", rate))"
    }
}

// MARK: - Top Movers Section

struct TopMoversSection: View {
    let topMovers: [Stock]
    let onStockTapped: (Stock) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section title
            Text("급상승")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tumoInk)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            // Rows
            ForEach(Array(topMovers.enumerated()), id: \.element.stockCode) { index, stock in
                Button(action: {
                    onStockTapped(stock)
                }) {
                    TopMoverRow(stock: stock)
                }
                .buttonStyle(.plain)

                if index < topMovers.count - 1 {
                    Rectangle()
                        .fill(Color.tumoHairlineSoft)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct TopMoverRow: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.stockName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)
                    .lineLimit(1)

                Text(stock.stockCode)
                    .font(.system(size: 13, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoMuted)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(stock.currentPrice.formatted())원")
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoInk)

                HStack(spacing: 2) {
                    if let changeRate = stock.changeRate {
                        Text(formatChangeRate(changeRate))
                            .font(.system(size: 12, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(changeRateColor(changeRate))
                    } else {
                        Text("—")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.tumoMuted)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func formatChangeRate(_ rate: Decimal) -> String {
        String(format: "%+.2f%%", (rate as NSDecimalNumber).doubleValue)
    }

    private func changeRateColor(_ rate: Decimal) -> Color {
        rate >= 0 ? Color.tumoUp : Color.tumoDown
    }
}

// MARK: - Recent Orders Section

struct RecentOrdersSection: View {
    let recentOrders: [OrderHistoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section title
            Text("최근 주문")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tumoInk)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            if recentOrders.isEmpty {
                Text("최근 주문이 없습니다")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(recentOrders.enumerated()), id: \.element.id) { index, order in
                    RecentOrderRow(order: order)

                    if index < recentOrders.count - 1 {
                        Rectangle()
                            .fill(Color.tumoHairlineSoft)
                            .frame(height: 1)
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecentOrderRow: View {
    let order: OrderHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.stockName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    OrderTypeBadge(orderType: order.orderType)

                    Text("\(order.quantity)주")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(order.executedPrice.formatted())원")
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoInk)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct OrderTypeBadge: View {
    let orderType: String

    var body: some View {
        Text(orderType == "BUY" ? "매수" : "매도")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                orderType == "BUY" ? Color.tumoUp : Color.tumoDown,
                in: Capsule()
            )
    }
}

// MARK: - States

struct HomeSkeletonRow: View {
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

struct HomeErrorState: View {
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

// MARK: - Preview

#Preview("홈 - 정상 상태") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    portfolio: Portfolio(
                        cashBalance: 5_000_000,
                        totalStockValue: 15_000_000,
                        totalAsset: 20_000_000,
                        profitAmount: 2_500_000,
                        profitRate: 12.5,
                        holdings: []
                    ),
                    topMovers: [
                        Stock(
                            stockCode: "005930",
                            stockName: "삼성전자",
                            market: "KOSPI",
                            currentPrice: 75_000,
                            changePrice: 1_000,
                            changeRate: 1.35,
                            tradeVolume: 10_000_000,
                            tradeAmount: 750_000_000_000,
                            priceChangedAt: "2024-01-15T15:30:00"
                        ),
                        Stock(
                            stockCode: "000660",
                            stockName: "SK하이닉스",
                            market: "KOSPI",
                            currentPrice: 170_000,
                            changePrice: 2_000,
                            changeRate: 1.19,
                            tradeVolume: 5_000_000,
                            tradeAmount: 850_000_000_000,
                            priceChangedAt: "2024-01-15T15:30:00"
                        ),
                    ],
                    recentOrders: [
                        OrderHistoryItem(
                            orderId: 1,
                            stockCode: "005930",
                            stockName: "삼성전자",
                            orderType: "BUY",
                            quantity: 10,
                            executedPrice: 74_500,
                            totalAmount: 745_000,
                            realizedProfit: nil,
                            executedAt: "2024-01-15T14:30:00"
                        ),
                        OrderHistoryItem(
                            orderId: 2,
                            stockCode: "000660",
                            stockName: "SK하이닉스",
                            orderType: "SELL",
                            quantity: 5,
                            executedPrice: 168_000,
                            totalAmount: 840_000,
                            realizedProfit: 50_000,
                            executedAt: "2024-01-14T10:15:00"
                        ),
                    ]
                )
            ) {
                HomeFeature()
            }
        )
    }
}

#Preview("홈 - 빈 상태") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    portfolio: Portfolio(
                        cashBalance: 10_000_000,
                        totalStockValue: 0,
                        totalAsset: 10_000_000,
                        profitAmount: 0,
                        profitRate: 0,
                        holdings: []
                    ),
                    topMovers: [],
                    recentOrders: []
                )
            ) {
                HomeFeature()
            }
        )
    }
}
