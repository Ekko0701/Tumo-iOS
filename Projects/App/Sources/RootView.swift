import AuthFeature
import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.route {
            case .loading:
                ProgressView()

            case .auth:
                AuthView(
                    store: store.scope(
                        state: \.auth,
                        action: \.auth
                    )
                )

            case .main:
                MainView()
            }
        }
        .task {
            store.send(.appStarted)
        }
    }
}

#Preview {
    RootView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
