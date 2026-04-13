import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State var currentMode: LandingView.AuthMode
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var animateIn = false

    init(initialMode: LandingView.AuthMode) {
        _currentMode = State(initialValue: initialMode)
    }

    var isSignIn: Bool { currentMode == .signIn }

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F").ignoresSafeArea()


            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSignIn ? "Welcome back" : "Create account")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(isSignIn ? "Sign in to your Mozart workspace" : "Join Mozart and start composing")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                    // Mode Toggle
                    HStack(spacing: 0) {
                        ForEach(["Sign In", "Sign Up"], id: \.self) { label in
                            let mode: LandingView.AuthMode = label == "Sign In" ? .signIn : .signUp
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    currentMode = mode
                                    errorMessage = nil
                                }
                            } label: {
                                Text(label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(currentMode == mode ? .white : Color.white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        currentMode == mode ?
                                        Color(hex: "#7C4FE4").opacity(0.8) : Color.clear
                                    )
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .opacity(animateIn ? 1 : 0)

                    // Form Fields
                    VStack(spacing: 14) {
                        if !isSignIn {
                            MozartTextField(
                                placeholder: "Full Name",
                                text: $name,
                                icon: "person.fill"
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }

                        MozartTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )

                        MozartTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )

                        if !isSignIn {
                            MozartTextField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                icon: "lock.fill",
                                isSecure: true
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .animation(.spring(response: 0.35), value: isSignIn)
                    .opacity(animateIn ? 1 : 0)

                    // Error
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                            Text(error)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(Color(hex: "#FF6B6B"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#FF6B6B").opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Submit
                    Button {
                        Task { await handleSubmit() }
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text(isSignIn ? "Sign In" : "Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: isLoading
                                    ? [Color(hex: "#7C4FE4").opacity(0.5), Color(hex: "#5A32C8").opacity(0.5)]
                                    : [Color(hex: "#7C4FE4"), Color(hex: "#5A32C8")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "#7C4FE4").opacity(isLoading ? 0.1 : 0.35), radius: 12, y: 4)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(animateIn ? 1 : 0)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                        Text("or").font(.system(size: 12)).foregroundColor(Color.white.opacity(0.3)).padding(.horizontal, 12)
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Google OAuth placeholder
                    Button {
                        // OAuth flow - opens browser / ASWebAuthenticationSession
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continue with Google")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 48)
                    .opacity(animateIn ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
    }

    @MainActor
    private func handleSubmit() async {
        withAnimation { errorMessage = nil }
        guard validate() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if isSignIn {
                try await authManager.signIn(email: email, password: password)
            } else {
                try await authManager.signUp(name: name, email: email, password: password)
            }
        } catch let error as APIError {
            withAnimation { errorMessage = error.localizedDescription }
        } catch {
            withAnimation { errorMessage = error.localizedDescription }
        }
    }

    private func validate() -> Bool {
        if email.isEmpty || password.isEmpty {
            withAnimation { errorMessage = "Email and password are required." }
            return false
        }
        if !isSignIn {
            if name.isEmpty {
                withAnimation { errorMessage = "Name is required." }
                return false
            }
            if password != confirmPassword {
                withAnimation { errorMessage = "Passwords do not match." }
                return false
            }
            if password.count < 6 {
                withAnimation { errorMessage = "Password must be at least 6 characters." }
                return false
            }
        }
        return true
    }
}

struct MozartTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure = false
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isFocused ? Color(hex: "#9B6FF5") : Color.white.opacity(0.35))
                .frame(width: 20)

            Group {
                if isSecure && !isRevealed {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.white)
            .focused($isFocused)

            if isSecure {
                Button { isRevealed.toggle() } label: {
                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(isFocused ? 0.08 : 0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color(hex: "#7C4FE4").opacity(0.7) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
