import CoreDesignSystem
import SwiftUI

// MARK: - Header

/// 종목 목록 상단 타이틀/부제 헤더.
struct StockListHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("종목")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.tumoInk)

            Text("실시간 종목 랭킹 Top 30")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Sort Segment

/// 정렬 옵션(거래대금/거래량/상승/하락)을 가로 스크롤 칩으로 보여주는 세그먼트.
struct StockSortSegment: View {
    let selected: StockSortOption
    let onSelect: (StockSortOption) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StockSortOption.allCases) { option in
                    let isSelected = option == selected

                    Button {
                        onSelect(option)
                    } label: {
                        Text(option.title)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.tumoInk : Color.tumoMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.tumoSurfaceStrong : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - States

/// 로딩 중 목록 자리를 채우는 스켈레톤 행.
struct StockSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.tumoSurfaceStrong)
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.tumoSurfaceSoft)
                    .frame(width: 76, height: 12)
            }

            Spacer(minLength: 12)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.tumoSurfaceStrong)
                .frame(width: 64, height: 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

/// 목록 조회 실패 상태. 재시도 버튼을 제공한다.
struct StockErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoBody)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("다시 시도")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.tumoBlue, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 96)
    }
}

/// 조회 가능한 종목이 없을 때의 빈 상태.
struct StockEmptyState: View {
    let sortOption: StockSortOption

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.tumoMutedSoft)

            Text(emptyMessage)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 96)
    }

    private var emptyMessage: String {
        if sortOption == .watchlist {
            "관심종목이 없어요. 종목 상세에서 ★을 눌러 추가해 보세요."
        } else {
            "조회 가능한 종목이 없습니다."
        }
    }
}
