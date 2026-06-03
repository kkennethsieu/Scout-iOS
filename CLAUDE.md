# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Scout is a **photographer-focused spot-discovery app** — find, view, and review good photo locations. SwiftUI, multi-platform (iOS, iPadOS, macOS, visionOS).

Main surfaces (a custom tab bar in `App/MainTabView.swift`, not a stock `TabView`):
- **Explore** — searchable/filterable/sortable feed of spots (`SpotCard`s with a photo carousel).
- **Map** — spots as pins (MapKit); tap a pin → preview → detail. Has a "search this area" re-query and a recenter-to-user button.
- **Spot Detail** — hero photos, stats, shooting times, gear/composition, access logistics, reviews.
- **Saved / Profile** — placeholders; Profile shows the signed-in user + sign out.
- **Create (+)** — entry sheet (`ShareSpotSheet`) to upload a photo or use current location. **The downstream create flow is currently being rebuilt** — `CreateSpotFlow` just presents the entry sheet with stubbed callbacks.

## Working conventions (follow these for every change)

- **Write tests for new functionality.** Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`) — not XCTest. New view models / models / logic get coverage in `ScoutTests/`; view-model tests inject a stub `SpotService` (see existing tests for the pattern).
- **Reuse existing components — don't create near-duplicates.** Before building any UI, check `Components/` and the screen's local `Components/` folder, and extend/parameterize what's there. Only add a new component when nothing fits.
- **Use the design system; stay visually consistent.** Colors from `Color.s*`, fonts from `Font.s*`, spacing/radii from the `Spacing`/`Radius` enums. No raw hex, system colors, or magic-number padding. Match the spacing, sizing, and layout rhythm of existing screens.
- **Follow Apple's Human Interface Guidelines** — navigation patterns, hit targets, dynamic type/accessibility, and platform-appropriate behavior.

## App entry & auth

- `ScoutApp` calls `FirebaseApp.configure()`, injects `AuthService.shared` with `.environment`, and renders **`RootView`**.
- `RootView` gates on auth state: `auth.isResolvingAuth` → `SplashScreen`; `auth.isAuthenticated` → `MainTabView`; otherwise → `AuthScreen`. **The app boots into the login screen unless signed in.**
- Auth is **Firebase** (Sign in with Apple / Google / email), in `Screens/Auth/`. `AuthService.shared` is the singleton; read it via `@Environment(AuthService.self)`. Its `idToken()` supplies `LiveSpotService`'s Bearer header.
- The backend creates all user records; the frontend only authenticates and forwards the Firebase ID token.

## Architecture

MVVM with SwiftUI `@Observable @MainActor` view models. Folders under `Scout/`:
- `App/` — `ScoutApp` (entry), `RootView` (auth gate), `MainTabView` (custom tab bar).
- `Screens/` — feature screens grouped by area (`Auth`, `Explore`, `Map`, `SpotDetail`, `Create`), each often with a local `Components/` subfolder.
- `Components/` — shared UI, in subfolders: `Buttons`, `Cards`, `Detail`, `Forms` (e.g. `SSheetHeader`, chip groups), `Map`, `Navigation` (`STabBar`), `States` (loading/error/empty).
- `DesignSystem/` — **`s`-prefixed design tokens**: `Color.sAccent`/`sBackground`/…, `Font.sHeadingM`/`sBodyS`/…, and `Spacing`/`Radius` enums. These are the source of truth for styling.
- `ViewModels/`, `Models/`, `Services/`, `Extensions/`, `Resources/`, `Assets.xcassets`.

### UI patterns to preserve
- **Tab persistence:** `MainTabView` keeps all tabs instantiated and shows/hides them by `opacity`/`zIndex` (not a swapping `TabView`), so each tab's scroll position and nav stack survive switching. Don't "simplify" this to a stock `TabView`.
- **`TabBarVisibility`:** an `@Observable` (in `Components/Navigation/STabBar.swift`) passed via `.environment`. Screens hide the tab bar by toggling `isHidden` in `onAppear`/`onDisappear` (e.g. Spot Detail).

### Service layer (data)
- `SpotService` protocol with two implementations: `LiveSpotService` (backend at `http://localhost:8000`, Firebase Bearer token) and `MockSpotService` (sample data).
- **`AppServices.spot`** is the default dependency used everywhere: it auto-selects **`LiveSpotService` on the simulator** and **`MockSpotService` on a real device** (a device can't reach localhost). View models take an injectable `SpotService` for tests/previews.
- Backend routes: only `GET /spots` is confirmed; `GET /spots/{id}` and `GET /spots/{id}/reviews` (paginated) are assumed. JSON is snake_case + ISO-8601 → decoded via `JSONDecoder.scout`.
- Models: `Spot` (`SpotSummary`/`SpotDetail`), `Review`, `User`, `PhotoMetadata` (EXIF/GPS read from picked-photo `Data` via ImageIO — no photo-library permission needed), `SpotRegion`. `LocationManager` wraps CoreLocation and has a **DEBUG fixed-location override** for dev.

## Build / Run

Open in Xcode: `open Scout.xcodeproj`. Deployment target is **26.1** (iOS/macOS/visionOS) — needs the matching Xcode/SDK.

```bash
# Build for iOS Simulator (pick an INSTALLED device; iPhone 16 is often not installed — use iPhone 17)
xcodebuild -project Scout.xcodeproj -scheme Scout -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests (Swift Testing)
xcodebuild -project Scout.xcodeproj -scheme Scout -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Targets: `Scout` and `ScoutTests`. Dependencies are via **Swift Package Manager (resolved in Xcode, no `Package.swift`)**: Firebase (Auth) and GoogleSignIn. No linter config, no CI.

## Xcode project conventions

- The `Scout/` group uses a **`PBXFileSystemSynchronizedRootGroup`** (Xcode 16+). New `.swift` files dropped into `Scout/` are picked up automatically — do **not** hand-edit `project.pbxproj` to register them.
- Build settings of note:
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — new types are MainActor-isolated by default. Mark value types used across actors / for protocol conformances (`Hashable`, `Decodable`, `SpotService`) **`nonisolated`** explicitly.
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`.
  - App sandbox + hardened runtime on; `com.apple.security.network.client` and `personal-information.location` entitlements set. ATS allows `NSAllowsLocalNetworking` for the localhost backend.
  - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx xros xrsimulator"`, `TARGETED_DEVICE_FAMILY = "1,2,7"`. **Platform-specific code must compile across all of them** — avoid iOS-only modifiers like `navigationBarTitleDisplayMode` / `.topBarTrailing`; use cross-platform equivalents (`.cancellationAction`, etc.).
- Bundle identifier: `test.Scout`. Development team: `QQ58W2SAUH`.

## Gotchas (hard-won)

- **AsyncImage width blow-out:** a loaded image reports its native size and can stretch its container. The fix used across the codebase: a `Color` base + `.overlay { AsyncImage… }` + `.clipped()`, plus `containerRelativeFrame` for paged content and a FlowLayout ideal-size fallback. Reuse this pattern for any remote image.
- **iPhone 16 simulator is usually not installed** — use **iPhone 17** in `-destination`.
- **MainActor-by-default** means forgetting `nonisolated` on a value type breaks `Hashable`/`Decodable`/protocol conformance — annotate explicitly.

## Security / hygiene

- **`GoogleService-Info.plist` must NOT be committed**, and `.claude/` must be fully gitignored. No secrets in commits.
- Backend owns user records; the app only authenticates and forwards the Firebase token.
