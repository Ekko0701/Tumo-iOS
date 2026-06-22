import CoreDesignSystem
import SwiftUI

/// 시장 구분(KOSPI/KOSDAQ 등) 배지. 목록·상세 양쪽에서 공용으로 쓴다.
struct MarketBadge: View {
    let market: String

    var body: some View {
        Text(market)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.tumoBlue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.tumoBlue.opacity(0.08), in: Capsule())
    }
}

/// 아이콘 + 제목 + 부제로 빈/에러 상태를 표현하는 공용 메시지 뷰.
struct MessageState: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.tumoMutedSoft)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tumoBody)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.tumoMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}
