/// 종목 랭킹 기준. rawValue는 백엔드 `StockRankingType` enum과 일치한다.
public enum StockRankingType: String, CaseIterable, Equatable, Sendable {
    /// Tumo 내부 사용자 행동 데이터 기반 인기 랭킹.
    case popular = "POPULAR"
    /// 거래대금 상위 랭킹.
    case tradeAmount = "TRADE_AMOUNT"
    /// 거래량 상위 랭킹.
    case tradeVolume = "TRADE_VOLUME"
    /// 전일 대비 급상승 랭킹.
    case rising = "RISING"
    /// 전일 대비 급하락 랭킹.
    case falling = "FALLING"
}
