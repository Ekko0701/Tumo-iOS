/// 종목 시장 구분. rawValue는 백엔드 `Market` enum과 일치한다.
public enum StockMarket: String, CaseIterable, Equatable, Sendable {
    case kospi = "KOSPI"
    case kosdaq = "KOSDAQ"
}
