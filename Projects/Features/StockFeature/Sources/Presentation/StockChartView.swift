import Charts
import CoreDesignSystem
import SwiftUI

// MARK: - Chart Content

/// 차트 탭 본문. 시간 단위 세그먼트 + 상태별(에러/로딩/빈/차트) 본문을 렌더링한다.
struct ChartContent: View {
    let candles: [StockCandle]
    let selectedInterval: CandleInterval
    let isLoading: Bool
    let errorMessage: String?
    let onSelectInterval: (CandleInterval) -> Void
    let onRetry: () -> Void
    /// 차트를 과거(왼쪽 끝)로 스크롤해 더 받을 시점에 호출된다.
    let onReachedLeadingEdge: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            IntervalSegment(selected: selectedInterval, onSelect: onSelectInterval)
            chartBody
        }
    }

    @ViewBuilder
    private var chartBody: some View {
        if let errorMessage {
            VStack(spacing: 12) {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                Button(action: onRetry) {
                    Text("다시 시도")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.tumoBlue)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        } else if candles.isEmpty {
            if isLoading {
                ProgressView()
                    .tint(Color.tumoMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("표시할 데이터가 없습니다")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            CandleChart(
                candles: candles,
                visibleDomain: selectedInterval.visibleDomainSeconds,
                onReachedLeadingEdge: onReachedLeadingEdge
            )
            // interval이 바뀌면 데이터·스크롤 상태를 새로 시작하도록 뷰 정체성을 교체한다.
            .id(selectedInterval)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Interval Segment

/// 분/일/주/월/년 시간 단위 선택 세그먼트.
struct IntervalSegment: View {
    let selected: CandleInterval
    let onSelect: (CandleInterval) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CandleInterval.allCases) { interval in
                let isSelected = interval == selected

                Button {
                    onSelect(interval)
                } label: {
                    Text(interval.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.tumoInk : Color.tumoMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.tumoSurfaceStrong : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Candle Chart

/// OHLCV 캔들 차트. 고가~저가 꼬리 + 시가~종가 몸통을 그린다.
///
/// 가로 스크롤이 가능하며, 한 화면에 `visibleDomain`(초)만큼만 보여준다.
/// 왼쪽(과거) 끝 근처로 스크롤하면 `onReachedLeadingEdge`로 추가 로딩을 요청한다.
/// x축이 날짜라서 앞쪽에 데이터를 prepend해도 보던 위치가 그대로 유지된다.
struct CandleChart: View {
    let candles: [StockCandle]
    let visibleDomain: TimeInterval
    let onReachedLeadingEdge: () -> Void

    /// 보이는 영역의 왼쪽(과거) 끝 시각. nil이면 최신 구간으로 정렬한다.
    @State private var scrollPositionDate: Date?

    var body: some View {
        Chart(candles) { candle in
            // 고가~저가 꼬리.
            RuleMark(
                x: .value("시각", candle.candleTime),
                yStart: .value("저가", candle.lowPrice),
                yEnd: .value("고가", candle.highPrice)
            )
            .foregroundStyle(color(for: candle))

            // 시가~종가 몸통.
            RectangleMark(
                x: .value("시각", candle.candleTime),
                yStart: .value("시가", candle.openPrice),
                yEnd: .value("종가", candle.closePrice),
                width: .ratio(0.6)
            )
            .foregroundStyle(color(for: candle))
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleDomain)
        .chartScrollPosition(x: scrollBinding)
        .onAppear(perform: anchorToLatestIfNeeded)
        // interval 전환 등으로 최신 봉이 바뀌면 다시 최신 구간으로 정렬한다.
        .onChange(of: candles.last?.candleTime) { _, _ in
            scrollPositionDate = nil
            anchorToLatestIfNeeded()
        }
    }

    /// 스크롤 위치 바인딩. 값이 바뀔 때 왼쪽 끝이 가장 이른 봉 근처면 추가 로딩을 요청한다.
    private var scrollBinding: Binding<Date> {
        Binding(
            get: { scrollPositionDate ?? defaultLeadingEdge },
            set: { newValue in
                scrollPositionDate = newValue

                guard let earliest = candles.first?.candleTime else {
                    return
                }

                // 왼쪽 끝이 가장 이른 봉으로부터 반 화면 이내로 들어오면 과거를 더 받는다.
                if newValue.timeIntervalSince(earliest) < visibleDomain / 2 {
                    onReachedLeadingEdge()
                }
            }
        )
    }

    /// 최신 봉이 오른쪽 끝에 오도록 한 화면 앞을 왼쪽 끝으로 잡는다.
    private var defaultLeadingEdge: Date {
        (candles.last?.candleTime ?? Date()).addingTimeInterval(-visibleDomain)
    }

    private func anchorToLatestIfNeeded() {
        if scrollPositionDate == nil {
            scrollPositionDate = defaultLeadingEdge
        }
    }

    private func color(for candle: StockCandle) -> Color {
        candle.closePrice >= candle.openPrice ? Color.tumoUp : Color.tumoDown
    }

    private var yDomain: ClosedRange<Int> {
        let lows = candles.map(\.lowPrice)
        let highs = candles.map(\.highPrice)

        guard let minLow = lows.min(), let maxHigh = highs.max() else {
            return 0 ... 1
        }

        // 위아래 약간의 여백을 둬 캔들이 가장자리에 붙지 않게 한다.
        let padding = max(1, (maxHigh - minLow) / 20)
        return (minLow - padding) ... (maxHigh + padding)
    }
}
