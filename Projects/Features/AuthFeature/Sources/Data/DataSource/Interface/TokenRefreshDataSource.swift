/// Token Refresh API 호출을 담당하는 DataSource 인터페이스.
///
/// DataSource는 서버 응답 DTO를 그대로 반환한다.
protocol TokenRefreshDataSource: Sendable {
    func refreshToken(requestDTO: TokenRefreshRequestDTO) async throws -> LoginResponseDTO
}
