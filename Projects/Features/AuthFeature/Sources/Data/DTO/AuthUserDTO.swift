import Foundation

/// `GET /api/v1/users/me` 응답. `AuthUser` 도메인 엔티티로 매핑된다.
struct AuthUserDTO: Decodable, Sendable, Equatable {
    let id: Int64
    let email: String
    let nickname: String
    let cashBalance: Int64
}
