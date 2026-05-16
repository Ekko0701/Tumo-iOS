import ComposableArchitecture
import SwiftUI

public struct AuthView: View {
    private let store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            LoginView(
                store: store.scope(
                    state: \.login,
                    action: \.login
                )
            )
            .navigationDestination(
                isPresented: Binding(
                    get: { store.isSignupScreenPresented },
                    set: { isPresented in
                        if !isPresented {
                            store.send(.signupBackButtonTapped)
                        }
                    }
                )
            ) {
                SignupView(
                    store: store.scope(
                        state: \.signup,
                        action: \.signup
                    )
                )
            }
        }
    }
}
