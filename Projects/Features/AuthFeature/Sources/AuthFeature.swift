import ComposableArchitecture

@Reducer
public struct AuthFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var title = "Tumo"
        public var subtitle = "AuthFeature Demo"
        public var loginTapCount = 0

        public init() {}
    }

    public enum Action: Equatable {
        case loginButtonTapped
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loginButtonTapped:
                state.loginTapCount += 1
                return .none
            }
        }
    }
}
