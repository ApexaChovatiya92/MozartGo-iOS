import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ComposeView()
                .tabItem {
                    Label("Compose", systemImage: "wand.and.stars")
                }
                .tag(0)

            WorkbenchView()
                .tabItem {
                    Label("Workbench", systemImage: "folder.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .tint(Color(hex: "#9B6FF5"))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#0E0E16"))
            appearance.shadowColor = UIColor(Color.white.opacity(0.05))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
