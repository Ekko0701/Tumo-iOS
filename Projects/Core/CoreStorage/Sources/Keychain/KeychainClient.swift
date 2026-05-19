import ComposableArchitecture
import Foundation
import Security

/// iOS Keychain에 `Data`를 저장, 조회, 삭제하는 저수준 저장소 클라이언트.
public struct KeychainClient: Sendable {
    public var save: @Sendable (_ data: Data, _ key: String) throws -> Void
    public var read: @Sendable (_ key: String) throws -> Data
    public var delete: @Sendable (_ key: String) throws -> Void
}

public extension KeychainClient {
    static func live(service: String = "com.tumo.core-storage") -> KeychainClient {
        KeychainClient(
            save: { data, key in
                var deleteQuery = Self.baseQuery(service: service, key: key)
                let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)

                guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
                    throw KeychainError.unexpectedStatus(deleteStatus)
                }

                deleteQuery[kSecValueData as String] = data
                deleteQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

                let addStatus = SecItemAdd(deleteQuery as CFDictionary, nil)

                switch addStatus {
                case errSecSuccess:
                    return
                case errSecDuplicateItem:
                    throw KeychainError.duplicateItem
                default:
                    throw KeychainError.unexpectedStatus(addStatus)
                }
            },
            read: { key in
                var query = Self.baseQuery(service: service, key: key)
                query[kSecReturnData as String] = true
                query[kSecMatchLimit as String] = kSecMatchLimitOne

                var item: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &item)

                switch status {
                case errSecSuccess:
                    guard let data = item as? Data else {
                        throw KeychainError.unexpectedStatus(status)
                    }

                    return data
                case errSecItemNotFound:
                    throw KeychainError.itemNotFound
                default:
                    throw KeychainError.unexpectedStatus(status)
                }
            },
            delete: { key in
                let query = Self.baseQuery(service: service, key: key)
                let status = SecItemDelete(query as CFDictionary)

                switch status {
                case errSecSuccess:
                    return
                case errSecItemNotFound:
                    throw KeychainError.itemNotFound
                default:
                    throw KeychainError.unexpectedStatus(status)
                }
            }
        )
    }

    private static func baseQuery(service: String, key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

private enum KeychainClientKey: DependencyKey {
    static let liveValue = KeychainClient.live()
}

public extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClientKey.self] }
        set { self[KeychainClientKey.self] = newValue }
    }
}
