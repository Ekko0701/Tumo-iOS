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
                baseVisibleCount: selectedInterval.baseVisibleCandleCount,
                onReachedLeadingEdge: onReachedLeadingEdge
            )
            // interval이 바뀌면 데이터·스크롤·줌 상태를 새로 시작하도록 뷰 정체성을 교체한다.
            .id(selectedInterval)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
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

/// 캔들(OHLCV) + 이동평균선 + 거래량 패널을 함께 그리는 차트.
///
/// x축은 "최신 봉 기준 위치(offset)"라 봉이 균일하게 두껍게 그려지고, 과거 봉 prepend 시 위치가 유지된다.
/// 핀치 줌으로 보이는 봉 개수를 조절하며, 개수가 적을수록 봉이 두꺼워진다.
struct CandleChart: View {
    private static let minZoom: CGFloat = 0.25
    private static let maxZoom: CGFloat = 6
    private static let minVisibleCount = 5
    private static let maxVisibleCount = 400
    private static let bodyWidthRatio = 0.7

    let candles: [StockCandle]
    /// 줌 1배일 때 한 화면에 보일 봉 개수.
    let baseVisibleCount: Int
    let onReachedLeadingEdge: () -> Void

    /// 보이는 영역의 왼쪽(과거) 끝 위치. nil이면 최신 구간으로 정렬한다.
    @State private var scrollPosition: Int?
    /// 제스처로 확정된 줌 배율.
    @State private var committedZoom: CGFloat = 1
    /// 핀치 진행 중의 실시간 배율(끝나면 committedZoom에 반영).
    @GestureState private var gestureZoom: CGFloat = 1

    var body: some View {
        let points = CandlePlot.points(candles)

        GeometryReader { geometry in
            // 봉/거래량 막대 폭을 "플롯 폭 ÷ 보이는 봉 개수"로 직접 계산한다.
            // (연속 x축에서는 .ratio가 폭을 보장하지 못해 .fixed로 픽셀 폭을 지정한다.)
            let bodyWidth = candleBodyWidth(containerWidth: geometry.size.width)

            VStack(spacing: 6) {
                legend
                priceChart(points, bodyWidth: bodyWidth)
                    .frame(minHeight: 230)
                volumeChart(points, bodyWidth: bodyWidth)
                    .frame(height: 84)
            }
            .simultaneousGesture(magnifyGesture)
            // 스크롤 끝(과거) 근처 도달 시 추가 로딩. 부수효과는 setter가 아니라 onChange에서 처리한다.
            .onChange(of: scrollPosition) { _, newValue in
                guard let leading = newValue else {
                    return
                }

                let oldest = -(candles.count - 1)
                if leading <= oldest + visibleCount / 2 {
                    onReachedLeadingEdge()
                }
            }
            // interval 전환·재조회 등으로 최신 봉이 바뀌면 다시 최신 구간으로 정렬한다(nil → 기본 위치).
            .onChange(of: candles.last?.candleTime) { _, _ in
                scrollPosition = nil
            }
        }
    }

    /// 화면 폭과 보이는 봉 개수로 봉 몸통의 픽셀 폭을 계산한다. 줌으로 개수가 줄면 폭이 커진다.
    private func candleBodyWidth(containerWidth: CGFloat) -> CGFloat {
        let yAxisInset: CGFloat = 44 // 우측 가격 라벨 영역(추정)
        let plotWidth = max(1, containerWidth - yAxisInset)
        let slotWidth = plotWidth / CGFloat(max(1, visibleCount))
        return max(1.5, slotWidth * Self.bodyWidthRatio)
    }

    // MARK: Price chart

    private func priceChart(_ points: [CandlePlotPoint], bodyWidth: CGFloat) -> some View {
        Chart {
            ForEach(points) { point in
                // 고가~저가 꼬리.
                RuleMark(
                    x: .value("위치", point.positionFromLatest),
                    yStart: .value("저가", Double(point.candle.lowPrice)),
                    yEnd: .value("고가", Double(point.candle.highPrice))
                )
                .foregroundStyle(color(for: point.candle))

                // 시가~종가 몸통.
                RectangleMark(
                    x: .value("위치", point.positionFromLatest),
                    yStart: .value("시가", Double(point.candle.openPrice)),
                    yEnd: .value("종가", Double(point.candle.closePrice)),
                    width: .fixed(bodyWidth)
                )
                .foregroundStyle(color(for: point.candle))
                .cornerRadius(1)
            }

            // 이동평균선(5/20/60/120).
            ForEach(Self.movingAverages) { series in
                ForEach(points) { point in
                    if let value = series.value(point) {
                        LineMark(
                            x: .value("위치", point.positionFromLatest),
                            y: .value("MA\(series.id)", value),
                            series: .value("MA", series.id)
                        )
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: 1.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
        }
        .chartYScale(domain: priceDomain)
        .chartYAxis { AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) }
        .chartXAxis(.hidden)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleCount)
        .chartScrollPosition(x: scrollBinding)
    }

    // MARK: Volume chart

    private func volumeChart(_ points: [CandlePlotPoint], bodyWidth: CGFloat) -> some View {
        Chart(points) { point in
            BarMark(
                x: .value("위치", point.positionFromLatest),
                y: .value("거래량", Double(point.candle.tradeVolume)),
                width: .fixed(bodyWidth)
            )
            .foregroundStyle(color(for: point.candle))
        }
        .chartYAxis { AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) }
        .chartXAxis {
            AxisMarks(values: xAxisPositions) { value in
                if let position = value.as(Int.self), let date = date(forPosition: position) {
                    AxisGridLine()
                    AxisValueLabel { Text(Self.dateLabel.string(from: date)) }
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleCount)
        .chartScrollPosition(x: scrollBinding)
    }

    // MARK: Legend

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(Self.movingAverages) { series in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(series.color)
                        .frame(width: 8, height: 8)

                    Text("\(series.id)")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoMuted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }

    // MARK: Zoom

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($gestureZoom) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                committedZoom = Self.clampZoom(committedZoom * value.magnification)
            }
    }

    /// 줌을 반영해 실제 표시할 봉 개수. 확대할수록 적게(=두껍게) 보인다.
    private var visibleCount: Int {
        let zoom = Self.clampZoom(committedZoom * gestureZoom)
        let raw = Int((Double(baseVisibleCount) / Double(zoom)).rounded())
        let upperBound = min(Self.maxVisibleCount, max(Self.minVisibleCount, candles.count))
        return min(max(raw, Self.minVisibleCount), upperBound)
    }

    // MARK: Scroll position

    /// nil이면 최신 구간을 보여주고, setter는 값 저장만 한다(부수효과는 onChange에서).
    private var scrollBinding: Binding<Int> {
        Binding(
            get: { scrollPosition ?? defaultLeadingPosition },
            set: { scrollPosition = $0 }
        )
    }

    /// 최신 봉이 오른쪽 끝에 오도록 한 화면 앞을 왼쪽 끝으로 잡는다.
    private var defaultLeadingPosition: Int {
        -(visibleCount - 1)
    }

    // MARK: Axes / colors

    private func date(forPosition position: Int) -> Date? {
        let index = position + (candles.count - 1)
        guard candles.indices.contains(index) else {
            return nil
        }
        return candles[index].candleTime
    }

    private var xAxisPositions: [Int] {
        guard !candles.isEmpty else {
            return []
        }
        let oldest = -(candles.count - 1)
        let step = max(1, visibleCount / 3)
        return Array(stride(from: 0, through: oldest, by: -step))
    }

    private var priceDomain: ClosedRange<Double> {
        let lows = candles.map { Double($0.lowPrice) }
        let highs = candles.map { Double($0.highPrice) }

        guard let minLow = lows.min(), let maxHigh = highs.max() else {
            return 0 ... 1
        }

        let padding = max(1, (maxHigh - minLow) / 20)
        return (minLow - padding) ... (maxHigh + padding)
    }

    private func color(for candle: StockCandle) -> Color {
        candle.closePrice >= candle.openPrice ? Color.tumoUp : Color.tumoDown
    }

    private static func clampZoom(_ value: CGFloat) -> CGFloat {
        min(max(value, minZoom), maxZoom)
    }

    private static let dateLabel: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "MM.dd"
        return formatter
    }()

    private struct MovingAverageSeries: Identifiable {
        let id: Int
        let color: Color
        let value: (CandlePlotPoint) -> Double?
    }

    private static let movingAverages: [MovingAverageSeries] = [
        MovingAverageSeries(id: 5, color: .orange, value: { $0.ma5 }),
        MovingAverageSeries(id: 20, color: .purple, value: { $0.ma20 }),
        MovingAverageSeries(id: 60, color: .blue, value: { $0.ma60 }),
        MovingAverageSeries(id: 120, color: .green, value: { $0.ma120 })
    ]
}
