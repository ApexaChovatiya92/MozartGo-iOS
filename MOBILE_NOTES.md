# MOBILE_NOTES.md — Mozart Go: Mobile Engineering Notes

## API Layer Design

### Architecture

The API layer is a single `APIService` singleton class with typed async methods. Each endpoint maps to one Swift function with a concrete return type — no raw `[String: Any]` dictionaries leak into ViewModels or Views.

```
APIService (singleton)
├── Generic `get<T: Decodable>(path:)` → handles auth header, decoding, error mapping
├── Generic `post<T: Decodable, B: Encodable>(path:body:requiresAuth:)` → same + body encoding
├── `streamCompletion(...)` → async stream via URLSession.bytes (SSE)
└── Retry logic → up to 2 retries with 500ms backoff, skips 401 (non-retryable)
```

### Date Decoding

The Mozart API may return ISO-8601 dates with or without fractional seconds. The decoder tries both formats via a custom `dateDecodingStrategy` rather than crashing on the first miss.

### Error Handling

All network errors are mapped to a typed `APIError` enum:

| HTTP Status | Swift Error |
|-------------|-------------|
| 401 | `.unauthorized` → triggers `AuthManager.signOut()` |
| 404 | `.notFound` |
| 5xx | `.serverError(code)` |
| Decoding fails | `.decodingError(underlying)` |
| URLError | `.networkError(underlying)` |

This means ViewModels only catch `APIError` cases — they never inspect raw `NSError` codes.

### SSE Streaming Design

```swift
// URLSession.bytes opens a persistent async stream
let (bytes, response) = try await session.bytes(for: request)

// Line-by-line SSE parsing
for try await line in bytes.lines {
    if line.hasPrefix("data: ") {
        let payload = String(line.dropFirst(6))
        if payload == "[DONE]" { break }
        // Parse JSON → extract token → yield to AsyncThrowingStream
    }
}
```

The stream is wrapped in `AsyncThrowingStream<String, Error>` so the ViewModel can iterate tokens with `for try await token in stream`. The task is stored as `streamTask: Task<Void, Never>?` so it can be cancelled mid-stream when the user taps Stop.

**Supported response formats:**
- OpenAI-style: `choices[0].delta.content`
- Simple: `{ "token": "..." }`
- Text field: `{ "text": "..." }`
- Raw string fallback

---

## Caching Approach

### What is cached and why

| Data | Cached | Storage | Reason |
|------|--------|---------|--------|
| Workbench items | ✅ Yes | UserDefaults (JSON) | Offline read requirement |
| Conversations list | ✅ Yes | UserDefaults (JSON) | History sheet needs it |
| Chat messages | ❌ No | In-memory only | Streaming-first; cache adds complexity |
| User profile | ❌ No | AuthManager @Published | Loaded fresh on app launch |
| JWT token | ✅ Yes | Keychain | Security requirement |

### Cache limit

The last **20 items** are stored for Workbench, matching the spec's "10-20 items" requirement. Items are sliced with `.prefix(20)` before encoding.

### Cache invalidation

| Event | Cache Action |
|-------|-------------|
| Logout | `CacheService.clearAll()` wipes all UserDefaults keys |
| Pull-to-refresh (online) | Fresh API data overwrites cache |
| Pull-to-refresh (offline) | Shows cached data + orange banner |
| Item deleted (online) | Local array mutated + cache re-written |

### Why UserDefaults instead of Core Data / SwiftData?

For a case study with a 1-week timeline, UserDefaults JSON encoding is:
- Zero setup (no schema, migrations, model files)
- Fully testable without persistent store setup
- Sufficient for <20 items of flat data

**For production**, I would migrate to **SwiftData** (iOS 17+) because:
- Native Swift models with `@Model` macro
- Automatic iCloud sync potential
- Richer queries for filtering/sorting without manual Array operations
- Lazy loading for large datasets

---

## Authentication Approach

**Implemented: Email/Password (Option A from the spec)**

The mobile app POST to `/api/v1/auth/sign-in` and `/api/v1/auth/sign-up` with JSON bodies. The response is expected to contain a `token` field (JWT). This token is stored in the iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

**Google OAuth (Option C — scaffolded, not wired)**

The UI shows a "Continue with Google" button. To fully implement:
1. Use `ASWebAuthenticationSession` to open `GET /api/v1/auth/signinWithGoogle` in a browser session
2. Capture the redirect callback URL via a custom URL scheme (`mozartgo://oauth`)
3. Extract the token from the callback query parameters
4. Save to Keychain via `KeychainService`

This is a ~2 hour implementation blocked on knowing the exact redirect URL and callback format from the dev environment.

**Session persistence**: On cold launch, `AuthManager.init()` checks Keychain for an existing token. If present, it sets `isAuthenticated = true` immediately (zero loading flash) and then fires `loadCurrentUser()` async to populate `currentUser`. If the token is stale, the 401 response triggers `signOut()`.

---

## What I Would Improve With More Time

### Week 2 Priorities

**1. SwiftData persistence**
Replace `UserDefaults` JSON cache with SwiftData models. This enables offline-first behavior for messages too, not just workbench items — users could see their full conversation history offline.

**2. Full Google OAuth**
Wire `ASWebAuthenticationSession` to the Mozart OAuth callback. This is the primary auth path for web users and should be the default on mobile too.

**3. Optimistic UI**
Message sends currently wait for API confirmation before showing in the list. With optimistic UI, the user message appears instantly and we reconcile/rollback on failure.

**4. Proper mock layer for testing**
Extract `APIServiceProtocol` and inject mocks into ViewModels during tests. Current tests avoid the network by testing pure logic, but ViewModel integration tests would require mock injection.

**5. Haptic feedback**
`UIImpactFeedbackGenerator` on send, stream completion, and errors — small detail that significantly improves feel.

**6. Attachment support**
The compose bar has a placeholder clip icon. Full implementation: `PHPickerViewController` for images, `UIDocumentPickerViewController` for files, multipart upload to `/api/v1/file/create`.

**7. Push notifications**
Register for APNs, send device token to `/api/v1/user/settings`. Notify user when a long-running LLM task completes.

**8. Accessibility**
VoiceOver labels on all custom components, dynamic type support for font sizes, minimum 44pt tap targets audit.

**9. Widget extension**
A Lock Screen or Home Screen widget showing the last conversation or a quick compose shortcut — zero extra backend work needed.

**10. Error telemetry**
Integrate a crash/error reporting SDK (e.g. Sentry or Firebase Crashlytics) so the team can observe production issues without waiting for user reports.

---

## Known Limitations (Week 1)

- **Better Auth session cookies**: The web app uses cookie-based sessions. The mobile app assumes JWT tokens in the `Authorization` header. If the backend strictly requires cookies, `HTTPCookieStorage` would need to be configured on `URLSession`.
- **SSE format**: The parser handles common formats but the exact field names from `mozart.la`'s `/api/v1/completions` weren't verified against a live session. The fallback chain covers most variants.
- **No deep link handling**: Tapping a Mozart link from elsewhere won't route into the app.
- **iPad layout**: The current layout works on iPad but isn't optimized for split-view or the larger canvas.
