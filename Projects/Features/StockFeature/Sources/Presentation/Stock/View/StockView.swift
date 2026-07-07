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
            StockEmptyState(sortOption: store.sortOption)
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
