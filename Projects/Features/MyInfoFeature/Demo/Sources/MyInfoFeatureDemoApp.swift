import MyInfoFeature
import SwiftUI

@main
struct MyInfoFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MyInfoView(onLoggedOut: {})
            }
        }
    }
}
