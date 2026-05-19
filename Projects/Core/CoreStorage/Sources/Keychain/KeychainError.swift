import Foundation

/// iOS Keychain 접근 중 발생할 수 있는 저장소 에러.
public enum KeychainError: Error, Equatable, LocalizedError {
    /// 동일한 service/account 조합의 항목이 이미 존재.
    case duplicateItem

    /// 요청한 key에 해당하는 항목이 Keychain에 없음.
    case itemNotFound

    /// 명시적으로 분기하지 않은 Keychain OSStatus.
    case unexpectedStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .duplicateItem:
            "이미 저장된 Keychain 항목입니다."
        case .itemNotFound:
            "Keychain 항목을 찾을 수 없습니다."
        case let .unexpectedStatus(status):
            "Keychain 처리 중 알 수 없는 오류가 발생했습니다. status: \(status)"
        }
    }
}
