import AuthFeature
import ComposableArchitecture
import CoreStorage

@Reducer
struct AppFeature {
    @Dependency(\.tokenStorageClient) private var tokenStorageClient

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
        case authTokenLoaded(Bool)
        case authTokenLoadFailed
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

                let tokenStorageClient = tokenStorageClient

                return .run { send in
                    do {
                        let storedAuthToken = try tokenStorageClient.load()

                        await send(.authTokenLoaded(storedAuthToken != nil))
                    } catch {
                        await send(.authTokenLoadFailed)
                    }
                }

            case let .authTokenLoaded(hasToken):
                state.route = hasToken ? .main : .auth
                return .none

            case .authTokenLoadFailed:
                state.route = .auth
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
