import CoreDesignSystem
import SwiftUI

// MARK: - Order Book Content

/// 호가 탭 본문. 호가가 있으면 사다리(ladder)를, 없으면 대기 안내를 보여준다.
struct OrderBookContent: View {
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

// MARK: - Ladder

/// 매도(위)~매수(아래) 호가를 세로로 쌓아 보여주는 사다리.
struct OrderBookLadder: View {
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

// MARK: - Row

enum OrderBookSide {
    case ask
    case bid
}

/// 호가 한 줄(잔량 막대 + 가격 + 잔량 텍스트).
struct OrderBookRow: View {
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
