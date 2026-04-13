import SwiftUI

struct LandingView: View {
    @State private var showAuth = false
    @State private var authMode: AuthMode = .signIn
    @State private var animateIn = false

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#0A0A0F"), Color(hex: "#111118"), Color(hex: "#0D0D14")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle grid pattern overlay
            GeometryReader { geo in
                Canvas { context, size in
                    let spacing: CGFloat = 40
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    context.stroke(path, with: .color(Color.white.opacity(0.03)), lineWidth: 1)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Brand
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#7C4FE4"), Color(hex: "#4F2FC4")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(hex: "#7C4FE4").opacity(0.5), radius: 20, y: 8)

                        Text("M")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateIn ? 1 : 0.6)
                    .opacity(animateIn ? 1 : 0)

                    Text("Mozart Go")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                    Text("Your intelligent workspace,\nanywhere you go.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }

                Spacer()

                // Feature highlights
                VStack(spacing: 12) {
                    FeatureRow(icon: "bolt.fill", text: "Streaming AI responses, token by token")
                    FeatureRow(icon: "wifi.slash", text: "Offline access to your projects")
                    FeatureRow(icon: "folder.fill", text: "Workbench: files, folders, conversations")
                }
                .padding(.horizontal, 32)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)

                Spacer()

                // CTA Buttons
                VStack(spacing: 12) {
                    Button {
                        authMode = .signIn
                        showAuth = true
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#7C4FE4"), Color(hex: "#5A32C8")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color(hex: "#7C4FE4").opacity(0.4), radius: 12, y: 4)
                    }

                    Button {
                        authMode = .signUp
                        showAuth = true
                    } label: {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)

                Text("By continuing, you agree to our Terms & Privacy Policy")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    .opacity(animateIn ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateIn = true
            }
        }
        .fullScreenCover(isPresented: $showAuth) {
            AuthView(initialMode: authMode)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#9B6FF5"))
                .frame(width: 32, height: 32)
                .background(Color(hex: "#7C4FE4").opacity(0.15))
                .cornerRadius(8)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
