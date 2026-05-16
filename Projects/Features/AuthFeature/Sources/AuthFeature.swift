import ComposableArchitecture

@Reducer
public struct AuthFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var login = LoginFeature.State()
        public var signup = SignupFeature.State()
        public var isSignupScreenPresented = false

        public init() {}
    }

    public enum Action: Equatable {
        case login(LoginFeature.Action)
        case signup(SignupFeature.Action)
        case signupBackButtonTapped
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }

        Scope(state: \.signup, action: \.signup) {
            SignupFeature()
        }

        Reduce { state, action in
            switch action {
            case .login(.signupButtonTapped):
                state.isSignupScreenPresented = true
                state.signup = SignupFeature.State()
                return .none

            case .signupBackButtonTapped:
                state.isSignupScreenPresented = false
                state.signup = SignupFeature.State()
                return .none

            case .login, .signup:
                return .none
            }
        }
    }
}
