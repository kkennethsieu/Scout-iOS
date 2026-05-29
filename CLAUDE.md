# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Scout is a SwiftUI multi-platform app (iOS, iPadOS, macOS, visionOS). It is currently the bare Xcode template — `ScoutApp.swift` boots a `WindowGroup` containing `ContentView`, which is a placeholder "Hello, world!" view. Treat it as a greenfield project; there is no domain architecture to preserve yet.

## Build / Run

Open in Xcode: `open Scout.xcodeproj`.

Command-line builds (deployment target is **26.1** for iOS / macOS / visionOS — requires the matching Xcode/SDK):

```bash
# Build for iOS Simulator
xcodebuild -project Scout.xcodeproj -scheme Scout -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for macOS
xcodebuild -project Scout.xcodeproj -scheme Scout -destination 'platform=macOS' build
```

There is no test target configured yet — `xcodebuild test` will fail until one is added. There is no SwiftPM `Package.swift`, no linter config, and no CI.

## Xcode project conventions

- The `Scout/` group uses a **`PBXFileSystemSynchronizedRootGroup`** (Xcode 16+). New `.swift` files dropped into `Scout/` are picked up automatically — do **not** hand-edit `project.pbxproj` to register them.
- Build settings of note (in `project.pbxproj`):
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — new types are MainActor-isolated by default. Annotate `nonisolated` explicitly for background work.
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` are on.
  - `ENABLE_APP_SANDBOX = YES`, `ENABLE_HARDENED_RUNTIME = YES`, `ENABLE_USER_SELECTED_FILES = readonly` — adding write access to user files or network entitlements requires changing these.
  - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx xros xrsimulator"` and `TARGETED_DEVICE_FAMILY = "1,2,7"` (iPhone, iPad, visionOS). Any platform-specific code must compile across all of them.
- Bundle identifier: `test.Scout`. Development team: `QQ58W2SAUH`.
