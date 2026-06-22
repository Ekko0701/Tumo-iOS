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

    /// 한 번에 조회할 기간의 크기(달력 성분 + 음수 값).
    ///
    /// 분봉은 백엔드가 1회 조회를 최대 7일로 제한하므로 7일만 조회한다.
    /// 그 외에는 차트 표시에 충분한 과거 구간을 잡는다.
    /// `dateRange`(최초 조회)와 `previousRange`(스크롤 시 과거 추가 조회)가 공유한다.
    private var windowStep: (component: Calendar.Component, value: Int) {
        switch self {
        case .minute:
            (.day, -7)
        case .day:
            (.month, -6)
        case .week:
            (.year, -2)
        case .month:
            (.year, -5)
        case .year:
            (.year, -10)
        }
    }

    /// 시간 단위별 최초 조회 기간을 계산한다.
    ///
    /// - Parameters:
    ///   - now: 기준 시각(보통 오늘).
    ///   - calendar: 날짜 계산에 사용할 캘린더.
    /// - Returns: `from`(과거) ~ `to`(now) 조회 구간.
    public func dateRange(asOf now: Date, calendar: Calendar) -> (from: Date, to: Date) {
        let step = windowStep
        let from = calendar.date(byAdding: step.component, value: step.value, to: now) ?? now
        return (from, now)
    }

    /// 차트를 과거로 스크롤할 때, 현재 보유한 가장 이른 봉 **직전**의 한 구간을 계산한다.
    ///
    /// `to`를 `earliest` 하루 전으로 잡아 이미 보유한 구간과 겹치지 않게 한다.
    ///
    /// - Parameters:
    ///   - earliest: 현재 보유한 가장 이른 봉의 기준 시각.
    ///   - calendar: 날짜 계산에 사용할 캘린더.
    /// - Returns: `earliest` 직전의 `from` ~ `to` 조회 구간.
    public func previousRange(before earliest: Date, calendar: Calendar) -> (from: Date, to: Date) {
        let to = calendar.date(byAdding: .day, value: -1, to: earliest) ?? earliest
        let step = windowStep
        let from = calendar.date(byAdding: step.component, value: step.value, to: to) ?? to
        return (from, to)
    }

    /// 스크롤 가능한 차트에서 한 화면에 보일 가로 구간 길이(초).
    ///
    /// 조회 기간(`windowStep`)보다 작게 잡아 스크롤할 여백을 남긴다.
    public var visibleDomainSeconds: TimeInterval {
        let day: TimeInterval = 60 * 60 * 24

        switch self {
        case .minute:
            return 60 * 60 * 6        // 약 6시간
        case .day:
            return day * 60           // 약 60일
        case .week:
            return day * 7 * 26       // 약 26주
        case .month:
            return day * 30 * 24      // 약 24개월
        case .year:
            return day * 365 * 6      // 약 6년
        }
    }
}
