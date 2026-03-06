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
- **Models/** — Core Data models: `World` (connection config, owns aliases/triggers/gags/tickers), `Alias`, `Trigger`, `Gag`, `Ticker`. Uses MagicalRecord for Core Data convenience.
- **Controllers/Client/** — Active MUD session UI: `SSClientViewController` (terminal), `SSSessionLogger` (transcripts), `SPLWorldTickerManager` (periodic commands)
- **Controllers/Settings/** — World list, world editor, theme/sound/encoding pickers
- **Forms/** — QuickDialog/FXForms-based editors for aliases, triggers, gags, tickers
- **Views/** — `SSMudView` (terminal display), `SSGrowingTextView` (input), `SSTextTableView` (scrollback)
- **Additions/** — Category extensions on Foundation/UIKit classes

### Vendored Dependencies

All former CocoaPods are vendored as local Swift packages in `Vendored/`. Key ones:

- **CocoaAsyncSocket** — TCP socket library
- **libtelnet** — Telnet protocol primitives (C library)
- **SPLCore** — Shared utilities (depends on MagicalRecord and libextobjc)
- **MagicalRecord** — Core Data convenience layer
- **JASidePanels** — Side panel navigation
- **Masonry** — Auto Layout DSL
- **TTTAttributedLabel** — Rich text display

### Data Flow

1. `SSMUDSocket` opens TCP connection via CocoaAsyncSocket
2. Raw data passes through `SPLTelnetLib` for telnet negotiation and optional zlib decompression
3. `SSStringCoder` handles character encoding conversion
4. `SSANSIEngine` parses ANSI escape codes into `NSAttributedString`
5. `SSAttributedLineGroup` batches attributed strings for display
6. `SSMudView` / `SSTextTableView` renders the output

## Git

- **Main branch:** `trunk`
