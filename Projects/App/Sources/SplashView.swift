import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0, green: 82 / 255, blue: 1))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Text("T")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    Text("Tumo")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(Color(red: 10 / 255, green: 11 / 255, blue: 13 / 255))
                }

                ProgressView()
                    .tint(Color(red: 0, green: 82 / 255, blue: 1))
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SplashView()
}
