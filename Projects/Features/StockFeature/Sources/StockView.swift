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

            content
        }
        .navigationTitle("종목")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.refreshButtonTapped)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
        }
        .task {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.stocks.isEmpty {
            ProgressView()
                .tint(.tumoBlue)
        } else if let errorMessage = store.errorMessage, store.stocks.isEmpty {
            VStack(spacing: 16) {
                Text(errorMessage)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.tumoBody)
                    .multilineTextAlignment(.center)

                Button("다시 시도") {
                    store.send(.refreshButtonTapped)
                }
                .buttonStyle(.borderedProminent)
                .tint(.tumoBlue)
            }
            .padding(.horizontal, 24)
        } else if store.isEmptyStateVisible {
            Text("조회 가능한 종목이 없습니다.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoBody)
        } else {
            List {
                ForEach(store.stocks) { stock in
                    StockRow(stock: stock)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.tumoCanvas)
                }
            }
            .listStyle(.plain)
            .refreshable {
                store.send(.refreshButtonTapped)
            }
        }
    }
}

private struct StockRow: View {
    let stock: Stock

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stock.stockName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.tumoInk)

                    Text(stock.market)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.tumoBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.tumoBlue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                Text(stock.stockCode)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)
            }

            Spacer(minLength: 16)

            Text("\(stock.currentPrice.formatted())원")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tumoInk)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.tumoHairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private extension Color {
    static let tumoBlue = Color(red: 0, green: 82.0 / 255.0, blue: 1)
    static let tumoInk = Color(red: 10.0 / 255.0, green: 11.0 / 255.0, blue: 13.0 / 255.0)
    static let tumoBody = Color(red: 91.0 / 255.0, green: 97.0 / 255.0, blue: 110.0 / 255.0)
    static let tumoMuted = Color(red: 124.0 / 255.0, green: 130.0 / 255.0, blue: 138.0 / 255.0)
    static let tumoHairline = Color(red: 222.0 / 255.0, green: 225.0 / 255.0, blue: 230.0 / 255.0)
    static let tumoCanvas = Color.white
}

#Preview {
    NavigationStack {
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
                        )
                    ]
                )
            ) {
                StockFeature()
            }
        )
    }
}
