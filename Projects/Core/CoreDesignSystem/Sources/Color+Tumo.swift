import SwiftUI

// MARK: - Design Tokens (DESIGN.md, with Korean up/down convention)

/// 앱 전역에서 공유하는 Tumo 색 토큰.
///
/// 현재는 코드 리터럴로 정의돼 있다. 다크모드/고대비/P3 지원이 필요해지면
/// 본문을 에셋 카탈로그 접근자(`CoreDesignSystemAsset.tumoUp.swiftUIColor` 등)로
/// 교체한다. 그 경우에도 `Color.tumoX` 호출부는 그대로 유지된다.
public extension Color {
    static let tumoBlue = Color(red: 0, green: 82.0 / 255.0, blue: 1)
    static let tumoInk = Color(red: 10.0 / 255.0, green: 11.0 / 255.0, blue: 13.0 / 255.0)
    static let tumoBody = Color(red: 91.0 / 255.0, green: 97.0 / 255.0, blue: 110.0 / 255.0)
    static let tumoMuted = Color(red: 124.0 / 255.0, green: 130.0 / 255.0, blue: 138.0 / 255.0)
    static let tumoMutedSoft = Color(red: 168.0 / 255.0, green: 172.0 / 255.0, blue: 179.0 / 255.0)
    static let tumoHairline = Color(red: 222.0 / 255.0, green: 225.0 / 255.0, blue: 230.0 / 255.0)
    static let tumoHairlineSoft = Color(red: 238.0 / 255.0, green: 240.0 / 255.0, blue: 243.0 / 255.0)
    static let tumoSurfaceStrong = Color(red: 238.0 / 255.0, green: 240.0 / 255.0, blue: 243.0 / 255.0)
    static let tumoSurfaceSoft = Color(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0)
    static let tumoCanvas = Color.white

    // 등락 색상은 토스/한국 관습(상승=빨강, 하락=파랑).
    static let tumoUp = Color(red: 240.0 / 255.0, green: 68.0 / 255.0, blue: 82.0 / 255.0)
    static let tumoDown = Color(red: 49.0 / 255.0, green: 130.0 / 255.0, blue: 246.0 / 255.0)
}
