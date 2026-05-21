import ComposableArchitecture
import CoreStorage

@Reducer
public struct LoginFeature {
    @Dependency(\.authClient) private var authClient
    @Dependency(\.tokenStorageClient) private var tokenStorageClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var email = ""
        public var password = ""
        public var isLoading = false
        public var errorMessage: String?
        public var emailErrorMessage: String?
        public var passwordErrorMessage: String?
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
        case loginSucceeded
        case loginFailed(AuthFormError)
        case signupButtonTapped
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .emailChanged(email):
                state.email = email
                state.errorMessage = nil
                state.emailErrorMessage = nil
                state.successMessage = nil
                return .none

            case let .passwordChanged(password):
                state.password = password
                state.errorMessage = nil
                state.passwordErrorMessage = nil
                state.successMessage = nil
                return .none

            case .submitButtonTapped:
                guard state.isSubmitButtonEnabled else {
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil
                state.emailErrorMessage = nil
                state.passwordErrorMessage = nil
                state.successMessage = nil

                let email = state.email
                let password = state.password
                let authClient = authClient
                let tokenStorageClient = tokenStorageClient

                return .run { send in
                    do {
                        let authToken = try await authClient.login(email, password)
                        let storedAuthToken = StoredAuthToken(
                            accessToken: authToken.accessToken,
                            refreshToken: authToken.refreshToken,
                            tokenType: authToken.tokenType
                        )

                        try tokenStorageClient.save(storedAuthToken)
                        await send(.loginSucceeded)
                    } catch {
                        await send(.loginFailed(AuthErrorMessageMapper.formError(from: error)))
                    }
                }

            case .loginSucceeded:
                state.isLoading = false
                state.successMessage = "로그인에 성공했습니다."
                return .none

            case let .loginFailed(formError):
                state.isLoading = false
                state.errorMessage = formError.message
                state.emailErrorMessage = formError.emailMessage
                state.passwordErrorMessage = formError.passwordMessage
                return .none

            case .signupButtonTapped:
                return .none
            }
        }
    }
}
