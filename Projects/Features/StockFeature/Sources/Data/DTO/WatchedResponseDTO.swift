import Foundation

/// `GET /api/v1/watchlist/{stockCode}` 응답. 관심 등록 여부.
struct WatchedResponseDTO: Decodable, Sendable, Equatable {
    let watched: Bool
}
