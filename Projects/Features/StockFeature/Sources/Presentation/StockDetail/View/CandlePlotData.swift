import Foundation

/// 차트에 그릴 단일 캔들의 플롯 데이터.
///
/// x축은 날짜가 아니라 **최신 봉 기준 offset**(`positionFromLatest`)을 쓴다.
/// 최신 봉이 0, 그 직전이 -1 … 가장 이른 봉이 `-(count-1)`이다.
/// 이렇게 하면 봉이 주말·휴장 간격 없이 균일하게 그려지고, 과거 봉을 앞에 prepend해도
/// 기존 봉의 x값이 그대로라 스크롤 위치가 튀지 않는다.
struct CandlePlotPoint: Identifiable, Equatable {
    var id: Date { candle.candleTime }

    let positionFromLatest: Int
    let candle: StockCandle
    let ma5: Double?
    let ma20: Double?
    let ma60: Double?
    let ma120: Double?
}

/// `[StockCandle]`(시각 오름차순)을 차트 플롯 포인트로 변환한다.
enum CandlePlot {
    static func points(_ candles: [StockCandle]) -> [CandlePlotPoint] {
        guard !candles.isEmpty else {
            return []
        }

        let count = candles.count
        let closes = candles.map { Double($0.closePrice) }

        func movingAverage(window: Int, at index: Int) -> Double? {
            guard index >= window - 1 else {
                return nil
            }

            var sum = 0.0
            for offset in (index - window + 1) ... index {
                sum += closes[offset]
            }
            return sum / Double(window)
        }

        return candles.enumerated().map { index, candle in
            CandlePlotPoint(
                positionFromLatest: index - (count - 1),
                candle: candle,
                ma5: movingAverage(window: 5, at: index),
                ma20: movingAverage(window: 20, at: index),
                ma60: movingAverage(window: 60, at: index),
                ma120: movingAverage(window: 120, at: index)
            )
        }
    }
}
