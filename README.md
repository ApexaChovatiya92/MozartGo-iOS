# Mozart Go — Native iOS App

A modern, scalable iOS workspace application inspired by [Mozart](https://mozart.la), built with Swift 5.9+ and SwiftUI.

The app demonstrates a production-ready architecture with clean separation of concerns, dependency injection, offline-first capabilities, and a fully mockable API layer—allowing development and testing without backend dependency.

## Features

- **Landing** — Branded entry screen with animated onboarding and navigation flows
- **Auth** — Email/password authentication with JWT stored securely in Keychain (mock + real API ready)
- **Compose** — ChatGPT-like streaming interface using AsyncSequence; cancellable responses; conversation lifecycle
- **Workbench** — Hierarchical file & folder system (parentId-based) with offline caching per folder
- **Offline Support** — Intelligent caching (UserDefaults) with graceful fallback and error states
- **Mock API Support** — Fully functional app without backend using protocol-driven mock services
- **Clean Architecture** — MVVM + dependency injection + testable services
---


## Key Highlights

- ✅ Protocol-oriented API layer (`APIServiceProtocol`)
- ✅ Mock + Real API interchangeable via dependency injection
- ✅ Streaming architecture using `AsyncThrowingStream`
- ✅ Folder-based caching strategy (offline-first UX)
- ✅ Secure token handling via Keychain
- ✅ No third-party dependencies (pure Apple frameworks)

## Requirements

| Requirement | Version |
|-------------|---------|
| Xcode | 15.0+ |
| iOS Deployment Target | 17.0+ |
| Swift | 5.9+ |
| macOS (to build) | Sonoma 14.0+ |

No external dependencies — zero third-party packages. The app uses only Apple frameworks.

---

## Setup & Build

### 1. Clone Repository

```bash
git clone https://github.com/your-username/MozartGo-iOS.git
cd MozartGo-iOS

### 2. Open in Xcode

```
open MozartGo.xcodeproj

### 3. Build & Run

```
Product → Run  (⌘R)
Select: Any iOS Simulator or connected device
```

---

## Running on Simulator

```bash
# From command line (after project is set up)
xcodebuild -scheme MozartGo \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build

# Run tests
xcodebuild test \
           -scheme MozartGo \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Running Tests

In Xcode:
```
Product → Test  (⌘U)
```

Test coverage:
- `KeychainServiceTests` — save, retrieve, delete, overwrite token
- `CacheServiceTests` — cache/load workbench items, max-item limit (20), clear on logout
- `WorkbenchViewModelTests` — filter logic: all / files / folders / recent sort
- `ComposeViewModelTests` — initial state, cancel streaming, conversation reset
- `AuthManagerTests` — sign-out clears state

---

## Environment

The app targets the Mozart dev environment:
The app can run fully offline using the built-in Mock API service (default configuration).
```
API Base URL: https://api-dev.mozart.la
API Prefix:   /api/v1/
```

These are hardcoded in `APIService.swift`. To switch environments, change `baseURL`.

> **Do not commit credentials or JWT secrets to your repository.**

---

## Demo Flow (for Video)

### 1. Login Flow
1. Launch app → Landing screen
2. Tap **Sign In**
3. Enter credentials → tap Sign In
4. App transitions to Main Tab (Compose)

### 2. Offline Access
1. Open Workbench tab (items load and cache)
2. Enable Airplane Mode on device/simulator
3. Kill and relaunch app  
4. Navigate to Workbench → cached items appear
5. Orange "Offline" banner is shown
6. Pull-to-refresh → offline error shown clearly

### 3. Streaming Chat
1. Go to Compose tab
2. Type a prompt, tap Send
3. Watch tokens stream in real-time
4. Tap the red Stop button to cancel mid-stream
5. Tap the pencil icon to start a new conversation

### 4. Pull to Refresh & Error Handling
1. In Workbench, pull down to refresh (online)
2. Enable Airplane Mode and pull again
3. Error banner appears at bottom

---

## Architecture Summary

**Pattern**: MVVM + Dependency Injection  
**Concurrency**: Async/Await + Structured Concurrency (`@MainActor`)  
**Networking**: `URLSession` with retries, timeouts, typed error mapping  
**Streaming**: `URLSession.bytes` → `AsyncThrowingStream<String, Error>`  
**Persistence**: `UserDefaults` JSON (offline cache) + Keychain (JWT)  
**State**: `ObservableObject` + `@Published` + `@EnvironmentObject`  
**API Layer**: Protocol-based (`APIServiceProtocol`) enabling mock and production implementations  

See [iOS_ARCH.md](iOS_ARCH.md) for full architecture decisions.  
See [MOBILE_NOTES.md](MOBILE_NOTES.md) for API design, caching, and future improvements.

---

## Project Structure

```
MozartGo/
├── MozartGoApp.swift              # @main entry point
├── Models/
│   └── Models.swift               # All Codable data types
├── Views/
│   ├── RootView.swift             # Auth-gated routing
│   ├── MainTabView.swift          # Tab bar
│   ├── Landing/LandingView.swift  # Entry screen
│   ├── Auth/AuthView.swift        # Login + Signup
│   ├── Compose/ComposeView.swift  # Chat + streaming
│   ├── Workbench/WorkbenchView.swift  # Files/folders
│   └── Profile/ProfileView.swift  # User + sign out
├── ViewModels/
│   ├── ComposeViewModel.swift
│   └── WorkbenchViewModel.swift
├── Services/
│   ├── APIService.swift           # Typed network layer + SSE
│   ├── AuthManager.swift          # Session state
│   ├── KeychainService.swift      # Secure token storage
│   ├── CacheService.swift         # Offline caching
│   └── NetworkMonitor.swift       # NWPathMonitor
├── Extensions/
│   └── Color+Hex.swift
├── Tests/
│   └── MozartGoTests.swift
├── iOS_ARCH.md
├── MOBILE_NOTES.md
└── README.md
```

---

## Reviewer Access

Grant repository access to:
- edward@ryan-miranda.com
- vaibhav@ryan-miranda.com
- dhrruv@ryan-miranda.com
- vivek@ryan-miranda.com

---

## Submission Checklist

- [x] Landing screen
- [x] Auth screen (login + signup + validation + error states)
- [x] Compose screen (streaming SSE, cancel, history, empty/error states)
- [x] Workbench screen (list, detail, filters, pull-to-refresh, offline cache)
- [x] JWT stored in Keychain
- [x] Offline caching (last 20 items, clears on logout)
- [x] Async/Await concurrency, @MainActor
- [x] Typed API layer with retries and timeouts
- [x] Unit tests (ViewModels + Services)
- [x] iOS_ARCH.md
- [x] MOBILE_NOTES.md
- [x] README with setup + build + test instructions
- [ ] Demo video (record after building in Xcode)
- [ ] TestFlight / IPA / simulator build instructions (add after building)
