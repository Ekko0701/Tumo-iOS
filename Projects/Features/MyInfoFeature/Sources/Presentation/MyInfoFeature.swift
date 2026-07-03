import AuthFeature
import ComposableArchitecture

@Reducer
public struct MyInfoFeature {
    @Dependency(\.authClient) private var authClient

    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var profile: AuthUser?
        public var isLoading: Bool
        public var errorMessage: String?
        public var didLogout: Bool
        @Presents public var alert: AlertState<Action.Alert>?

        public init(profile: AuthUser? = nil, isLoading: Bool = false, errorMessage: String? = nil,
                    didLogout: Bool = false, alert: AlertState<Action.Alert>? = nil) {
            self.profile = profile
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.didLogout = didLogout
            self.alert = alert
        }
    }

    public enum Action: Equatable {
        case onAppear
        case profileLoaded(AuthUser)
        case loadFailed
        case logoutTapped
        case logoutSucceeded
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable, Sendable {
            case confirmLogout
        }
    }

    nonisolated(unsafe) public static let logoutAlert = AlertState<Action.Alert> {
        TextState("로그아웃")
    } actions: {
        ButtonState(role: .destructive, action: .confirmLogout) { TextState("로그아웃") }
        ButtonState(role: .cancel) { TextState("취소") }
    } message: {
        TextState("정말 로그아웃하시겠어요?")
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.profile == nil, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let authClient = authClient
                return .run { send in
                    do {
                        let user = try await authClient.fetchMe()
                        await send(.profileLoaded(user))
                    } catch {
                        await send(.loadFailed)
                    }
                }

            case let .profileLoaded(user):
                state.isLoading = false
                state.errorMessage = nil
                state.profile = user
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessage = "내 정보를 불러오지 못했습니다."
                return .none

            case .logoutTapped:
                state.alert = Self.logoutAlert
                return .none

            case .alert(.presented(.confirmLogout)):
                let authClient = authClient
                return .run { send in
                    // 백엔드 실패와 무관하게 로컬 토큰은 삭제됨 → 항상 로그아웃 처리
                    try? await authClient.logout()
                    await send(.logoutSucceeded)
                }

            case .alert:
                return .none

            case .logoutSucceeded:
                state.didLogout = true
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
