import ComposableArchitecture

@Reducer
public struct SignupFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var email = ""
        public var password = ""
        public var nickname = ""
        public var isLoading = false
        public var errorMessage: String?

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

            case let .nicknameChanged(nickname):
                state.nickname = nickname
                state.errorMessage = nil
                return .none

            case .submitButtonTapped:
                return .none
            }
        }
    }
}
