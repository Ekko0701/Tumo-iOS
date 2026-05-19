import ComposableArchitecture

@Reducer
public struct LoginFeature {
    @Dependency(\.authClient) private var authClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var email = ""
        public var password = ""
        public var isLoading = false
        public var errorMessage: String?
        public var successMessage: String?

        public init() {}

        public var title: String {
            "Tumo"
        }

        public var subtitle: String {
            "Sign in to continue"
        }

        public var submitButtonTitle: String {
            "로그인"
        }

        public var signupButtonTitle: String {
            "회원가입"
        }

        public var isSubmitButtonEnabled: Bool {
            !isLoading && !email.isEmpty && !password.isEmpty
        }
    }

    public enum Action: Equatable {
        case emailChanged(String)
        case passwordChanged(String)
        case submitButtonTapped
        case loginSucceeded(AuthToken)
        case loginFailed(String)
        case signupButtonTapped
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

            case .submitButtonTapped:
                guard state.isSubmitButtonEnabled else {
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil
                state.successMessage = nil

                let email = state.email
                let password = state.password
                let authClient = authClient

                return .run { send in
                    do {
                        let authToken = try await authClient.login(email, password)
                        await send(.loginSucceeded(authToken))
                    } catch {
                        await send(.loginFailed(AuthErrorMessageMapper.message(from: error)))
                    }
                }

            case .loginSucceeded:
                state.isLoading = false
                state.successMessage = "로그인에 성공했습니다."
                return .none

            case let .loginFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .signupButtonTapped:
                return .none
            }
        }
    }
}
