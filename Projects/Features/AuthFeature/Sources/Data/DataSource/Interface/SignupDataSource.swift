/// 회원가입 API 호출을 담당하는 DataSource 인터페이스.
///
/// DataSource는 서버 응답 DTO를 그대로 반환한다.
protocol SignupDataSource: Sendable {
    func signup(requestDTO: SignupRequestDTO) async throws -> SignupResponseDTO
}
