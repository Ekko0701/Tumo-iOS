import OrderFeature
import SwiftUI

@main
struct OrderFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OrderHistoryView()
            }
        }
    }
}
