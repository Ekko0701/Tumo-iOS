import ComposableArchitecture
import SwiftUI

public struct LoginView: View {
    private let store: StoreOf<LoginFeature>

    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(store.title)
                .font(.largeTitle)

            Text(store.subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField(
                    "이메일",
                    text: Binding(
                        get: { store.email },
                        set: { store.send(.emailChanged($0)) }
                    )
                )
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)

                SecureField(
                    "비밀번호",
                    text: Binding(
                        get: { store.password },
                        set: { store.send(.passwordChanged($0)) }
                    )
                )
                .textFieldStyle(.roundedBorder)
            }

            Button(store.submitButtonTitle) {
                store.send(.submitButtonTapped)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!store.isSubmitButtonEnabled)

            if store.isLoading {
                ProgressView()
            }

            if let successMessage = store.successMessage {
                Text(successMessage)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button(store.signupButtonTitle) {
                store.send(.signupButtonTapped)
            }
            .buttonStyle(.borderless)
        }
        .padding(24)
    }
}
