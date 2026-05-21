import ComposableArchitecture
import SwiftUI

public struct SignupView: View {
    private let store: StoreOf<SignupFeature>

    public init(store: StoreOf<SignupFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
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

                if let emailErrorMessage = store.emailErrorMessage {
                    Text(emailErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                SecureField(
                    "비밀번호",
                    text: Binding(
                        get: { store.password },
                        set: { store.send(.passwordChanged($0)) }
                    )
                )
                .textFieldStyle(.roundedBorder)

                if let passwordErrorMessage = store.passwordErrorMessage {
                    Text(passwordErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TextField(
                    "닉네임",
                    text: Binding(
                        get: { store.nickname },
                        set: { store.send(.nicknameChanged($0)) }
                    )
                )
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)

                if let nicknameErrorMessage = store.nicknameErrorMessage {
                    Text(nicknameErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
        }
        .navigationTitle(store.title)
        .padding(24)
    }
}
