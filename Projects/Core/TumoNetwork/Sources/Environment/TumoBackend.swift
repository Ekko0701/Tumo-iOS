import Foundation

/// Tumo 백엔드 서버 환경.
///
/// 모든 API endpoint(`TargetType`)가 참조하는 단일 base URL을 빌드 구성에 따라 분리한다.
/// 각 API가 URL을 하드코딩하지 않도록 여기 한 곳에서만 정의한다.
/// - Debug: 로컬 개발 서버
/// - Release: 운영 서버 (배포 전 실제 URL로 교체 필요)
public enum TumoBackend {
    /// 백엔드 base URL. 빌드 구성(Debug/Release)에 따라 분리된다.
    public static let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://localhost:8080")!
        #else
        // TODO: 운영 백엔드 배포 후 실제 URL로 교체한다.
        return URL(string: "https://api.tumo.app")!
        #endif
    }()
}
