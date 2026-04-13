# iOS_ARCH.md — Mozart Go Architecture

## Architecture Pattern: MVVM

### Why MVVM?

Mozart Go uses **MVVM (Model–View–ViewModel)** with SwiftUI-native patterns:

| Option | Decision |
|--------|----------|
| MVVM | ✅ Chosen — natural fit for SwiftUI, lightweight, testable |
| TCA (The Composable Architecture) | Considered — powerful but adds heavy dependency + learning curve |
| VIPER | Rejected — overengineered for a 1-week build; too many protocol layers |

MVVM aligns with how SwiftUI is designed: `View` observes `@Published` state on `ObservableObject` ViewModels. It keeps Views dumb (declarative rendering only) and makes ViewModels fully unit-testable without UIKit or SwiftUI imports.

---

## Layer Structure

```
MozartGo/
├── MozartGoApp.swift           # App entry point, injects environment objects
├── Models/
│   └── Models.swift            # Codable data types (User, Conversation, WorkbenchItem, etc.)
├── Views/
│   ├── RootView.swift          # Auth-gated routing
│   ├── Tab/MainTabView.swift       # Tab navigation
│   ├── Landing/LandingView.swift
│   ├── Auth/AuthView.swift
│   ├── Compose/ComposeView.swift
│   ├── Workbench/WorkbenchView.swift
│   └── Profile/ProfileView.swift
├── ViewModels/
│   ├── ComposeViewModel.swift
│   └── WorkbenchViewModel.swift
├── Services/
│   ├── APIService.swift        # Typed networking layer
│   ├── AuthManager.swift       # Session state (@MainActor singleton)
│   ├── KeychainService.swift   # Secure token storage
│   ├── CacheService.swift      # Offline persistence (UserDefaults JSON)
│   └── NetworkMonitor.swift    # NWPathMonitor wrapper
│   └── MockAPIService.swift    # Mock is available as of now no live data
├── Extensions/
│   └── Color+Hex.swift
└── Tests/
    └── MozartGoTests.swift
```

---

## State Management

**Choice: `ObservableObject` + `@Published` + `@EnvironmentObject`**

- `AuthManager.shared` → injected at root via `.environmentObject()`, drives `RootView` gating
- `NetworkMonitor.shared` → injected at root, consumed by all screens for offline UI
- `ComposeViewModel` and `WorkbenchViewModel` → `@StateObject` per-screen, not shared

**Why not Combine pipelines?**
We use `async/await` throughout (Swift Structured Concurrency), reserving Combine only where reactive publishers are natural (network path updates via `NWPathMonitor`). This reduces complexity significantly.

**@MainActor**
All ViewModels are `@MainActor` to guarantee `@Published` mutations happen on the main thread — no `DispatchQueue.main.async` scattered throughout.

---

## Navigation

- **Root level**: `RootView` renders either `LandingView` (unauthenticated) or `MainTabView` (authenticated), animated via `withAnimation`.
- **Tab bar**: `MainTabView` contains Compose, Workbench, and Profile tabs.
- **Stack**: `WorkbenchView` uses `NavigationStack` for push navigation into `WorkbenchDetailView`.
- **Sheets**: Auth is a `fullScreenCover`; conversation history is a `.sheet`.

---

## Offline Strategy

**Layer 1 — Detection**: `NetworkMonitor` wraps `NWPathMonitor`. Published `isConnected` flag propagates to all views via `@EnvironmentObject`.

**Layer 2 — Caching**: `CacheService` stores the last 20 Workbench items as JSON in `UserDefaults`. On network failure, `WorkbenchViewModel` falls back to cache automatically.

**Layer 3 — UI feedback**:
- `OfflineBanner` shown at top of Workbench and Compose when offline
- Pull-to-refresh is allowed but shows clear error if offline
- Workbench detail is read-only with a contextual note when offline
- Swipe-to-delete is hidden when offline

**Layer 4 — Logout cleanup**: `CacheService.clearAll()` is called on sign-out, preventing stale data from persisting for a different user.

---

## Concurrency Model

- All network calls use `async/await` with `URLSession.data(for:)` and `URLSession.bytes(for:)` (for SSE streaming)
- `Task { }` launched from SwiftUI `.task` modifiers and button handlers
- `streamTask: Task<Void, Never>?` stored on `ComposeViewModel` to allow cancellation
- Retries are implemented with a simple loop + `Task.sleep` backoff (up to 2 retries for idempotent GETs)

---

## SSE Streaming

The completions endpoint returns Server-Sent Events. Implementation:
1. `URLSession.bytes(for:)` opens an async byte stream
2. Lines are iterated with `for try await line in bytes.lines`
3. Lines prefixed with `data: ` are parsed as JSON
4. Supports both OpenAI-style (`choices[0].delta.content`) and simpler `{token: "..."}` payloads
5. `[DONE]` sentinel terminates the stream
6. Tokens are appended to `ComposeViewModel.streamingText`, which SwiftUI re-renders live

---

## Security

- JWT stored in **Keychain** (`kSecClassGenericPassword`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- Token never logged or stored in UserDefaults/plist
- On 401 response, `AuthManager.signOut()` is called to force re-authentication
- Keychain entry is deleted on logout

---

## Testing Strategy

- **Unit tests**: `KeychainServiceTests`, `CacheServiceTests`, `WorkbenchViewModelTests`, `ComposeViewModelTests`
- **ViewModel tests**: Pure logic tested without any UI or network — filter logic, cancel streaming, initial state
- **Network tests**: API service is a class; for production, extract a protocol (`APIServiceProtocol`) and inject mocks
- **UI tests**: Not implemented in Week 1; would use `XCUITest` targeting Login, Workbench list, and streaming behavior
