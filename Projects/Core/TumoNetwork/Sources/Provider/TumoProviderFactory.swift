import CoreNetwork
import CoreStorage
import Foundation

/// Tumo 앱에서 사용할 Provider 생성 정책을 모아두는 Factory.
///
/// Feature 모듈은 인증 인터셉터를 직접 생성하지 않고,
/// 공개 API용 Provider 또는 인증 API용 Provider 중 필요한 것을 요청한다.
public struct TumoProviderFactory: Sendable {
    public static let live = TumoProviderFactory()

    private let urlSession: URLSession
    private let tokenStorageClient: TokenStorageClient
    private let maxRetryCount: Int

    public init(
        urlSession: URLSession = .shared,
        tokenStorageClient: TokenStorageClient = .live(keychainClient: .live()),
        maxRetryCount: Int = 1
    ) {
        self.urlSession = urlSession
        self.tokenStorageClient = tokenStorageClient
        self.maxRetryCount = maxRetryCount
    }

    /// 인증이 필요 없는 API 요청에 사용할 Provider를 생성한다.
    ///
    /// 로그인, 회원가입, 토큰 재발급처럼 Authorization 헤더가 필요 없는 API에서 사용한다.
    public func publicProvider<Target: TargetType>() -> Provider<Target> {
        Provider<Target>(
            urlSession: urlSession,
            maxRetryCount: maxRetryCount
        )
    }

    /// 인증이 필요한 API 요청에 사용할 Provider를 생성한다.
    ///
    /// 요청 직전에 저장된 accessToken을 읽어 Authorization 헤더에 주입한다.
    public func authorizedProvider<Target: TargetType>() -> Provider<Target> {
        let authTokenInterceptor = AuthTokenInterceptor {
            try tokenStorageClient.load()?.accessToken
        }

        return Provider<Target>(
            urlSession: urlSession,
            interceptors: [
                authTokenInterceptor
            ],
            maxRetryCount: maxRetryCount
        )
    }
}
