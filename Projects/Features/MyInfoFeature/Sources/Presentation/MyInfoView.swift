import AuthFeature
import ComposableArchitecture
import CoreDesignSystem
import OrderFeature
import StockFeature
import SwiftUI

public struct MyInfoView: View {
    let onLoggedOut: () -> Void

    @Bindable var store: StoreOf<MyInfoFeature>

    public init(
        onLoggedOut: @escaping () -> Void,
        store: StoreOf<MyInfoFeature> = Store(initialState: .init()) { MyInfoFeature() }
    ) {
        self.onLoggedOut = onLoggedOut
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.tumoCanvas
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Profile header card
                    profileCard

                    // Menu list
                    menuList
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert($store.scope(state: \.alert, action: \.alert))
        .task {
            store.send(.onAppear)
        }
        .onChange(of: store.didLogout) { _, newValue in
            if newValue {
                onLoggedOut()
            }
        }
    }

    @ViewBuilder
    private var profileCard: some View {
        if store.isLoading && store.profile == nil {
            // Loading state
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color.tumoBlue)
                    .scaleEffect(1.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.tumoSurfaceStrong)
            .cornerRadius(12)
        } else if let errorMessage = store.errorMessage {
            // Error state
            VStack(spacing: 8) {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoDown)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.tumoSurfaceStrong)
            .cornerRadius(12)
        } else if let profile = store.profile {
            // Profile loaded
            VStack(alignment: .leading, spacing: 16) {
                // Nickname
                Text(profile.nickname)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.tumoInk)

                // Email
                Text(profile.email)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)

                // Cash balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("보유 현금")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.tumoMuted)

                    Text("\(profile.cashBalance.formatted())원")
                        .font(.system(size: 16, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.tumoInk)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.tumoSurfaceStrong)
            .cornerRadius(12)
        } else {
            // Default empty state (shouldn't show normally as it loads on appear)
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color.tumoBlue)
                    .scaleEffect(1.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.tumoSurfaceStrong)
            .cornerRadius(12)
        }
    }

    private var menuList: some View {
        VStack(spacing: 0) {
            // 주문 내역
            NavigationLink {
                OrderHistoryView()
            } label: {
                MenuRow(title: "주문 내역", systemImage: "arrow.left.arrow.right")
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.tumoHairlineSoft)
                .frame(height: 1)

            // 포트폴리오
            NavigationLink {
                PortfolioView()
            } label: {
                MenuRow(title: "포트폴리오", systemImage: "wallet.pass")
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.tumoHairlineSoft)
                .frame(height: 1)

            // 앱 정보
            MenuRow(
                title: "앱 정보",
                systemImage: "info.circle",
                trailingText: appVersion
            )

            Rectangle()
                .fill(Color.tumoHairlineSoft)
                .frame(height: 1)

            // 로그아웃
            Button {
                store.send(.logoutTapped)
            } label: {
                MenuRow(title: "로그아웃", systemImage: "rectangle.portrait.and.arrow.right", isDestructive: true)
            }
            .buttonStyle(.plain)
        }
        .background(Color.tumoSurfaceStrong)
        .cornerRadius(12)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }
}

// MARK: - MenuRow Component

struct MenuRow: View {
    let title: String
    let systemImage: String
    var trailingText: String?
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(isDestructive ? Color.tumoDown : Color.tumoBody)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(isDestructive ? Color.tumoDown : Color.tumoInk)

            Spacer()

            if let trailing = trailingText {
                Text(trailing)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.tumoMuted)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.tumoMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        MyInfoView(onLoggedOut: {})
    }
}
