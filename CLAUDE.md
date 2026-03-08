# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wammer is a fork of [MUDRammer](https://github.com/splinesoft/MUDRammer), an Objective-C iOS MUD client. The codebase has been modernized from CocoaPods to vendored Swift packages and from a hand-maintained Xcode project to Tuist-generated workspaces. Targets iOS 26.

## Build System

The project uses [Tuist](https://tuist.io) (v4.131.0) to generate the Xcode workspace from `Project.swift` and `Tuist.swift`.

```bash
tuist generate                # Generate Wammer.xcworkspace
```

Build and run from the generated `Wammer.xcworkspace` using the **Wammer** scheme.

### Running Tests

```bash
xcodebuild test \
  -workspace Wammer.xcworkspace \
  -scheme MRTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Test target is `MRTests` (defined in `Project.swift`). Tests use Expecta (assertions) and OCMock.

## Build Configuration Notes

- `CLANG_ENABLE_MODULES=YES` is required for `@import` syntax in ObjC
- `GCC_PREFIX_HEADER` points to `src/Mudrammer/Supporting Files/Mudrammer-Prefix.pch` (app) and `src/MRTests/MRTests-Prefix.pch` (tests)
- `HEADER_SEARCH_PATHS` includes `$(SRCROOT)/Vendored/**` and `$(SRCROOT)/src/Mudrammer/**`
- All vendored packages use `swift-tools-version: 6.2` with `.iOS(.v26)`

## Architecture

### Source Layout

All app source is under `src/Mudrammer/`. Tests are in `src/MRTests/`.

- **Network/** — Telnet/ANSI networking stack. Data flows: socket → `SPLTelnetLib` (telnet protocol + zlib) → `SSANSIEngine` (ANSI → NSAttributedString) → `SSMUDSocket` (delivers attributed line groups to UI)
- **Models/** — Currently empty; legacy Core Data models have been removed.
- **WorldStore/** — Swift Codable models (`MUDWorld`, `MUDAlias`, `MUDTrigger`, `MUDGag`, `MUDTicker` in `Models.swift`) with JSON flat-file persistence (`WorldStore.swift`). Business logic in `Models+Logic.swift`. ObjC bridging via `WorldStoreBridge.swift` and the auto-generated `Wammer-Swift.h`.
- **Controllers/Client/** — Active MUD session UI: `SSClientViewController` (terminal), `SSSessionLogger` (transcripts), `SPLWorldTickerManager` (periodic commands)
- **Controllers/Settings/** — World list, world editor, theme/sound/encoding pickers
- **Forms/** — QuickDialog/FXForms-based editors for aliases, triggers, gags, tickers
- **Views/** — `SSMudView` (terminal display), `SSGrowingTextView` (input), `SSTextTableView` (scrollback)
- **Additions/** — Category extensions on Foundation/UIKit classes

### Vendored Dependencies

All former CocoaPods are vendored as local Swift packages in `Vendored/`. Key ones:

- **CocoaAsyncSocket** — TCP socket library
- **libtelnet** — Telnet protocol primitives (C library)
- **SPLCore** — Shared utilities (depends on libextobjc)
- **JASidePanels** — Side panel navigation
- **Masonry** — Auto Layout DSL
- **TTTAttributedLabel** — Rich text display

### Persistence

World data is stored as JSON in `Documents/worlds.json` via `WorldStore` (singleton). No Core Data or MagicalRecord — all models are Swift `Codable` classes with `@objc`/`@objcMembers` for ObjC interop. Default worlds loaded from `DefaultWorlds.plist` on first launch.

### ObjC/Swift Bridging

**Swift → ObjC:** The auto-generated `Wammer-Swift.h` works and contains all `@objc` classes. ObjC files import `#import "Wammer-Swift.h"` to use Swift types.

**ObjC → Swift:** A bridging header at `src/Mudrammer/Supporting Files/Wammer-Bridging-Header.h` exposes ObjC types to Swift. Some ObjC headers that use `@import` for vendored SPM packages can't be imported directly in the bridging header — use forward declarations instead.

Swift classes use `@objc(ClassName)` and `@objcMembers` for ObjC interop. New Swift code should be written in Swift; avoid adding new ObjC classes.

### Multi-Window Architecture

The app uses the UIScene lifecycle for multi-window support on iPad and Mac Catalyst. Each window gets its own `WammerSceneDelegate` (Swift) which creates an independent `SSClientContainer` as root. There is no singleton container — view controllers find their container via the `UIViewController(SSClientContainerAccess)` category (`self.clientContainer` / `self.worldDisplay`). Menu bar actions are on `SSClientContainer` and route through the responder chain to the focused window.

### Data Flow

1. `SSMUDSocket` opens TCP connection via CocoaAsyncSocket
2. Raw data passes through `SPLTelnetLib` for telnet negotiation and optional zlib decompression
3. `SSStringCoder` handles character encoding conversion
4. `SSANSIEngine` parses ANSI escape codes into `NSAttributedString`
5. `SSAttributedLineGroup` batches attributed strings for display
6. `SSMudView` / `SSTextTableView` renders the output

## Design Guidelines

- **Avoid singletons.** They cause problems with multi-window and multi-connection architecture. Per-connection state should be owned by `SSClientViewController`. Always consider ownership and lifecycle before reaching for a singleton — they're rarely the right choice.

## Git

- **Main branch:** `trunk`
