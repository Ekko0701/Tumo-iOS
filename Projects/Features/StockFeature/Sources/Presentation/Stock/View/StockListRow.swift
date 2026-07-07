import CoreDesignSystem
import Foundation
import SwiftUI

/// 종목 목록의 단일 행. 순위 + 종목명/코드 + 현재가/지표를 보여준다.
struct StockRow: View {
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
        case .watchlist:
            "현재가 \(stock.currentPrice.formatted())"
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
