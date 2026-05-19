import ComposableArchitecture

@Reducer
public struct SignupFeature {
    @Dependency(\.authClient) private var authClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var email = ""
        public var password = ""
        public var nickname = ""
        public var isLoading = false
        public var errorMessage: String?
        public var successMessage: String?

        public init() {}

        public var title: String {
            "회원가입"
        }

        public var submitButtonTitle: String {
            "가입하기"
        }

        public var isSubmitButtonEnabled: Bool {
            !isLoading && !email.isEmpty && !password.isEmpty && !nickname.isEmpty
        }
    }

    public enum Action: Equatable {
        case emailChanged(String)
        case passwordChanged(String)
        case nicknameChanged(String)
        case submitButtonTapped
        case signupSucceeded(AuthUser)
        case signupFailed(String)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .emailChanged(email):
                state.email = email
                state.errorMessage = nil
                state.successMessage = nil
                return .none

            case let .passwordChanged(password):
                state.password = password
                state.errorMessage = nil
                state.successMessage = nil
                return .none

            case let .nicknameChanged(nickname):
                state.nickname = nickname
                state.errorMessage = nil
                state.successMessage = nil
                return .none

            case .submitButtonTapped:
                guard state.isSubmitButtonEnabled else {
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil
                state.successMessage = nil

                let email = state.email
                let password = state.password
                let nickname = state.nickname
                let authClient = authClient

                return .run { send in
                    do {
                        let authUser = try await authClient.signup(email, password, nickname)
                        await send(.signupSucceeded(authUser))
                    } catch {
                        await send(.signupFailed(AuthErrorMessageMapper.message(from: error)))
                    }
                }

            case .signupSucceeded:
                state.isLoading = false
                state.successMessage = "회원가입에 성공했습니다."
                return .none

            case let .signupFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }
}
