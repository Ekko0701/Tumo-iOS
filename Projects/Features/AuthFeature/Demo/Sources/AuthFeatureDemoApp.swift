import AuthFeature
import ComposableArchitecture
import SwiftUI

@main
struct AuthFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AuthView(
                store: Store(initialState: AuthFeature.State()) {
                    AuthFeature()
                }
            )
        }
    }
}
