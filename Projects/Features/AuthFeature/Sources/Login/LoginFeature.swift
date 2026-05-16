import ComposableArchitecture

@Reducer
public struct LoginFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var email = ""
        public var password = ""
        public var isLoading = false
        public var errorMessage: String?

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
        case signupButtonTapped
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .emailChanged(email):
                state.email = email
                state.errorMessage = nil
                return .none

            case let .passwordChanged(password):
                state.password = password
                state.errorMessage = nil
                return .none

            case .submitButtonTapped, .signupButtonTapped:
                return .none
            }
        }
    }
}
