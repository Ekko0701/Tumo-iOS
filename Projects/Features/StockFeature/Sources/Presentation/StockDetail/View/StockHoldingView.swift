import CoreDesignSystem
import SwiftUI

// MARK: - MY Stock Content

/// MY주식 탭 본문. 에러/로딩/보유/미보유 상태별로 분기한다.
struct MyStockContent: View {
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

// MARK: - Holding Card

/// 평가손익 + 보유 상세(수량/평단/현재가/평가금액) 카드.
struct HoldingCard: View {
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

// MARK: - Metric Row

/// 보유 상세의 라벨-값 한 줄.
struct HoldingMetricRow: View {
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
