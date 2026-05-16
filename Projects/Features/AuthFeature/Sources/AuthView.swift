import ComposableArchitecture
import SwiftUI

public struct AuthView: View {
    private let store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(store.title)
                .font(.largeTitle.bold())

            Text(store.subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("로그인") {
                store.send(.loginButtonTapped)
            }
            .buttonStyle(.borderedProminent)

            Text("로그인 버튼 탭 수: \(store.loginTapCount)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
