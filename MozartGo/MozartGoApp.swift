import SwiftUI

@main
struct MozartGoApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(networkMonitor)
                .preferredColorScheme(.dark)
        }
    }
}
