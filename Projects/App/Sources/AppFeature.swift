import AuthFeature
import ComposableArchitecture

@Reducer
struct AppFeature {
    @Dependency(\.authClient) private var authClient

    @ObservableState
    struct State: Equatable {
        var route: Route = .loading
        var auth = AuthFeature.State()

        enum Route: Equatable {
            case loading
            case auth
            case main
        }
    }

    enum Action: Equatable {
        case appStarted
        case sessionRefreshSucceeded
        case sessionRefreshFailed
        case logout
        case auth(AuthFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        Reduce { state, action in
            switch action {
            case .appStarted:
                state.route = .loading

                let authClient = authClient

                return .run { send in
                    do {
                        _ = try await authClient.refreshSession()
                        await send(.sessionRefreshSucceeded)
                    } catch {
                        await send(.sessionRefreshFailed)
                    }
                }

            case .sessionRefreshSucceeded:
                state.route = .main
                return .none

            case .sessionRefreshFailed:
                state.route = .auth
                return .none

            case .logout:
                state.route = .auth
                state.auth = AuthFeature.State()
                return .none

            case .auth(.login(.loginSucceeded)):
                state.route = .main
                return .none

            case .auth:
                return .none
            }
        }
    }
}
