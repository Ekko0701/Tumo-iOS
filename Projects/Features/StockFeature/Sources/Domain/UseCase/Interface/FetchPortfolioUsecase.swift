protocol FetchPortfolioUsecase: Sendable {
    func execute() async throws -> Portfolio
}
