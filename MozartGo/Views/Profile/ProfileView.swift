import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0A0A0F").ignoresSafeArea()

                List {
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#7C4FE4"), Color(hex: "#4F2FC4")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 56, height: 56)
                                Text(initials)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(authManager.currentUser?.name ?? "User")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(authManager.currentUser?.email ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.45))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.white.opacity(0.05))
                    }

                    Section("App") {
                        Label("Version 1.0.0", systemImage: "app.badge")
                            .foregroundColor(Color.white.opacity(0.6))
                            .listRowBackground(Color.white.opacity(0.04))

                        Label("mozart.la", systemImage: "globe")
                            .foregroundColor(Color.white.opacity(0.6))
                            .listRowBackground(Color.white.opacity(0.04))
                    }

                    Section("Account") {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color(hex: "#FF6B6B"))
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .toolbarBackground(Color(hex: "#0E0E16"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("Sign out of Mozart Go?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            }
        }
    }

    var initials: String {
        let name = authManager.currentUser?.name ?? "U"
        return name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}
