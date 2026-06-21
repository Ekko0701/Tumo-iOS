import Foundation

/// 차트 캔들의 시간 단위. `rawValue`는 백엔드 캔들 API의 `interval` 쿼리 값과 일치한다.
public enum CandleInterval: String, CaseIterable, Equatable, Sendable, Identifiable {
    case minute = "MINUTE"
    case day = "DAY"
    case week = "WEEK"
    case month = "MONTH"
    case year = "YEAR"

    public var id: String { rawValue }

    /// 세그먼트 표시용 한글 라벨.
    public var title: String {
        switch self {
        case .minute:
            "분"
        case .day:
            "일"
        case .week:
            "주"
        case .month:
            "월"
        case .year:
            "년"
        }
    }

    /// 시간 단위별 조회 기간을 계산한다.
    ///
    /// 분봉은 백엔드가 1회 조회를 최대 7일로 제한하므로 7일만 조회한다.
    /// 그 외에는 차트 표시에 충분한 과거 구간을 잡는다.
    ///
    /// - Parameters:
    ///   - now: 기준 시각(보통 오늘).
    ///   - calendar: 날짜 계산에 사용할 캘린더.
    /// - Returns: `from`(과거) ~ `to`(now) 조회 구간.
    public func dateRange(asOf now: Date, calendar: Calendar) -> (from: Date, to: Date) {
        let component: Calendar.Component
        let value: Int

        switch self {
        case .minute:
            component = .day
            value = -7
        case .day:
            component = .month
            value = -6
        case .week:
            component = .year
            value = -2
        case .month:
            component = .year
            value = -5
        case .year:
            component = .year
            value = -10
        }

        let from = calendar.date(byAdding: component, value: value, to: now) ?? now
        return (from, now)
    }
}
