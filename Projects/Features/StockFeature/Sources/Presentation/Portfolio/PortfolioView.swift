import ComposableArchitecture
import CoreDesignSystem
import Foundation
import SwiftUI

public struct PortfolioView: View {
    private let store: StoreOf<PortfolioFeature>

    public init(
        store: StoreOf<PortfolioFeature> = Store(initialState: PortfolioFeature.State()) {
            PortfolioFeature()
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
                    PortfolioHeader()
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
            item: $store.scope(state: \.detail, action: \.detail)
        ) { detailStore in
            StockDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.portfolio == nil {
            // Loading skeleton
            ForEach(0 ..< 5, id: \.self) { _ in
                PortfolioSkeletonRow()
            }
        } else if let errorMessage = store.errorMessage {
            // Error state
            PortfolioErrorState(message: errorMessage) {
                store.send(.refresh)
            }
        } else if let portfolio = store.portfolio {
            // Summary card
            PortfolioSummaryCard(portfolio: portfolio)

            // Holdings list or empty state
            if portfolio.holdings.isEmpty {
                PortfolioEmptyState()
            } else {
                ForEach(Array(portfolio.holdings.enumerated()), id: \.element.stockCode) { index, holding in
                    Button {
                        store.send(.holdingTapped(holding.stockCode))
                    } label: {
                        PortfolioHoldingRow(holding: holding)
                    }
                    .buttonStyle(.plain)

                    if index < portfolio.holdings.count - 1 {
                        Rectangle()
                            .fill(Color.tumoHairlineSoft)
                            .frame(height: 1)
                            .padding(.leading, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Header

struct PortfolioHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("포트폴리오")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.tumoInk)

            Text("나의 자산 현황")
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

struct PortfolioSummaryCard: View {
    let portfolio: Portfolio

    var body: some View {
        VStack(spacing: 16) {
            // 총자산 (큼)
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

            // 평가손익
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

                // 현금
                VStack(alignment: .leading, spacing: 4) {
                    Text("현금")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(portfolio.cashBalance.formatted())원")
                        .font(.system(size: 16, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoInk)
                }

                Spacer()

                // 보유평가액
                VStack(alignment: .leading, spacing: 4) {
                    Text("보유평가액")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(portfolio.totalStockValue.formatted())원")
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

// MARK: - Holding Row

struct PortfolioHoldingRow: View {
    let holding: StockHolding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 종목명, 수량
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.stockName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)
                        .lineLimit(1)

                    Text(holding.stockCode)
                        .font(.system(size: 13, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoMuted)
                }

                Spacer(minLength: 12)

                Text("\(holding.quantity)주")
                    .font(.system(size: 14, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(Color.tumoBody)
            }

            // 평단, 현재가, 평가금액
            HStack(spacing: 12) {
                PriceColumn(label: "평단", price: holding.averagePrice)
                PriceColumn(label: "현재가", price: holding.currentPrice)
                PriceColumn(label: "평가금액", price: holding.evaluationAmount)

                Spacer(minLength: 12)

                // 평가손익 (금액+수익률%)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(holding.profitAmount.formatted())원")
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(profitLossColor)

                    Text("(\(formatProfitRate(holding.profitRate))%)")
                        .font(.system(size: 12, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(profitLossColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var profitLossColor: Color {
        holding.profitAmount >= 0 ? Color.tumoUp : Color.tumoDown
    }

    private func formatProfitRate(_ rate: Double) -> String {
        let sign = rate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", rate))"
    }
}

private struct PriceColumn: View {
    let label: String
    let price: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.tumoMuted)

            Text("\(price.formatted())원")
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.tumoInk)
                .lineLimit(1)
        }
    }
}

// MARK: - States

struct PortfolioSkeletonRow: View {
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

struct PortfolioErrorState: View {
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

struct PortfolioEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "briefcase")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.tumoMutedSoft)

            Text("보유 종목이 없습니다.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
}

// MARK: - Preview

#Preview("포트폴리오 - 보유 종목 있음") {
    PortfolioView(
        store: Store(
            initialState: PortfolioFeature.State(
                portfolio: Portfolio(
                    cashBalance: 5_000_000,
                    totalStockValue: 15_000_000,
                    totalAsset: 20_000_000,
                    profitAmount: 2_500_000,
                    profitRate: 12.5,
                    holdings: [
                        StockHolding(
                            stockCode: "005930",
                            stockName: "삼성전자",
                            quantity: 100,
                            averagePrice: 65_000,
                            currentPrice: 75_000,
                            evaluationAmount: 7_500_000,
                            profitAmount: 1_000_000,
                            profitRate: 15.38
                        ),
                        StockHolding(
                            stockCode: "000660",
                            stockName: "SK하이닉스",
                            quantity: 50,
                            averagePrice: 140_000,
                            currentPrice: 170_000,
                            evaluationAmount: 8_500_000,
                            profitAmount: 1_500_000,
                            profitRate: 21.43
                        ),
                    ]
                )
            )
        ) {
            PortfolioFeature()
        }
    )
}

#Preview("포트폴리오 - 빈 상태") {
    PortfolioView(
        store: Store(
            initialState: PortfolioFeature.State(
                portfolio: Portfolio(
                    cashBalance: 10_000_000,
                    totalStockValue: 0,
                    totalAsset: 10_000_000,
                    profitAmount: 0,
                    profitRate: 0,
                    holdings: []
                )
            )
        ) {
            PortfolioFeature()
        }
    )
}
