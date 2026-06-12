import ComposableArchitecture
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
        ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    StockListHeader()

                    if !store.stocks.isEmpty {
                        StockSortSegment(selected: store.sortOption) { option in
                            store.send(.sortOptionChanged(option), animation: .easeInOut(duration: 0.2))
                        }
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
                StockRow(rank: index + 1, stock: stock)
                    .onAppear {
                        store.send(.rowAppeared(stockCode: stock.stockCode))
                    }

                if index < stocks.count - 1 {
                    Rectangle()
                        .fill(Color.tumoHairlineSoft)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }

            if store.isLoadingNextPage {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
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

            Text("실시간 인기 종목")
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
}

// MARK: - Row

private struct StockRow: View {
    let rank: Int
    let stock: Stock

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

            Text("\(stock.currentPrice.formatted())원")
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.tumoInk)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
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

// MARK: - Design Tokens (DESIGN.md, with Korean up/down convention)

private extension Color {
    static let tumoBlue = Color(red: 0, green: 82.0 / 255.0, blue: 1)
    static let tumoInk = Color(red: 10.0 / 255.0, green: 11.0 / 255.0, blue: 13.0 / 255.0)
    static let tumoBody = Color(red: 91.0 / 255.0, green: 97.0 / 255.0, blue: 110.0 / 255.0)
    static let tumoMuted = Color(red: 124.0 / 255.0, green: 130.0 / 255.0, blue: 138.0 / 255.0)
    static let tumoMutedSoft = Color(red: 168.0 / 255.0, green: 172.0 / 255.0, blue: 179.0 / 255.0)
    static let tumoHairline = Color(red: 222.0 / 255.0, green: 225.0 / 255.0, blue: 230.0 / 255.0)
    static let tumoHairlineSoft = Color(red: 238.0 / 255.0, green: 240.0 / 255.0, blue: 243.0 / 255.0)
    static let tumoSurfaceStrong = Color(red: 238.0 / 255.0, green: 240.0 / 255.0, blue: 243.0 / 255.0)
    static let tumoSurfaceSoft = Color(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0)
    static let tumoCanvas = Color.white

    // 등락 색상은 토스/한국 관습(상승=빨강, 하락=파랑). 등락률 데이터 도입 시 가격/변화율 셀에 사용한다.
    static let tumoUp = Color(red: 240.0 / 255.0, green: 68.0 / 255.0, blue: 82.0 / 255.0)
    static let tumoDown = Color(red: 49.0 / 255.0, green: 130.0 / 255.0, blue: 246.0 / 255.0)
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
                        priceChangedAt: "2026-05-13T15:30:00"
                    ),
                    Stock(
                        stockCode: "000660",
                        stockName: "SK하이닉스",
                        market: "KOSPI",
                        currentPrice: 180_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    ),
                    Stock(
                        stockCode: "035420",
                        stockName: "NAVER",
                        market: "KOSPI",
                        currentPrice: 190_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    ),
                    Stock(
                        stockCode: "035720",
                        stockName: "카카오",
                        market: "KOSDAQ",
                        currentPrice: 55_000,
                        priceChangedAt: "2026-05-13T15:30:00"
                    )
                ]
            )
        ) {
            StockFeature()
        }
    )
}
