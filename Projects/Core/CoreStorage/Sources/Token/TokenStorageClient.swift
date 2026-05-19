import ComposableArchitecture
import Foundation

/// 인증 토큰 저장, 조회, 삭제를 담당하는 앱 레벨 저장소 클라이언트.
public struct TokenStorageClient: Sendable {
    public var save: @Sendable (_ token: StoredAuthToken) throws -> Void
    public var load: @Sendable () throws -> StoredAuthToken?
    public var delete: @Sendable () throws -> Void
}

public extension TokenStorageClient {
    static func live(
        keychainClient: KeychainClient,
        tokenKey: String = "auth-token"
    ) -> TokenStorageClient {
        TokenStorageClient(
            save: { token in
                let data = try JSONEncoder().encode(token)

                try keychainClient.save(data, tokenKey)
            },
            load: {
                do {
                    let data = try keychainClient.read(tokenKey)

                    return try JSONDecoder().decode(StoredAuthToken.self, from: data)
                } catch KeychainError.itemNotFound {
                    return nil
                }
            },
            delete: {
                do {
                    try keychainClient.delete(tokenKey)
                } catch KeychainError.itemNotFound {
                    return
                }
            }
        )
    }
}

private enum TokenStorageClientKey: DependencyKey {
    static let liveValue = TokenStorageClient.live(
        keychainClient: .live()
    )
}

public extension DependencyValues {
    var tokenStorageClient: TokenStorageClient {
        get { self[TokenStorageClientKey.self] }
        set { self[TokenStorageClientKey.self] = newValue }
    }
}
