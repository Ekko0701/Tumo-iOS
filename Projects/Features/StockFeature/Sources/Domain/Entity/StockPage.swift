/// page 단위 종목 목록 조회 결과.
public struct StockPage: Equatable, Sendable {
    public let stocks: [Stock]
    public let page: Int
    public let hasNext: Bool

    public init(stocks: [Stock], page: Int, hasNext: Bool) {
        self.stocks = stocks
        self.page = page
        self.hasNext = hasNext
    }
}
