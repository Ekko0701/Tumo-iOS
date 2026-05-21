import ComposableArchitecture
import SwiftUI

@main
struct TumoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
