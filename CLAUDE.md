# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MUDRammer is an open-source iOS MUD (Multi-User Dungeon) client, originally developed 2012-2015. It is an Objective-C app targeting iOS 7+/8+ with an Xcode workspace + CocoaPods build system. The app was removed from the App Store in March 2025.

## Build System

The project uses CocoaPods for dependency management and Rake for build automation. All build commands run from the repo root.

```bash
rake setup    # Install gems + pods, wipe build output
rake test     # Build and run all tests via xcodebuild
rake lint     # Static analysis (cloc, FauxPas, fui, obcd)
rake ci       # setup + test + lint + coverage
```

The Xcode workspace is at `src/Mudrammer.xcworkspace`. Use the **MUDRammer Dev** scheme for development builds.

Tests run via `xcodebuild` piped through `xcpretty`, targeting iPhone 6 simulator.

## Architecture

### Networking Layer (`src/Mudrammer/Network/`)
- `SPLTelnetLib` — Full telnet protocol implementation including zlib compression, option negotiation, and MSSP. All server data must pass through this layer.
- `SSMUDSocket` — Socket wrapper using `GCDAsyncSocket`. Delegates parsed attributed line groups to the UI layer.
- `SSANSIEngine` — ANSI escape code parser, produces `NSAttributedString` output.
- `SSStringCoder` — Character encoding conversion.

### Data Model (`src/Mudrammer/Models/`)
Core Data-backed models via `SSMagicManagedObject`:
- `World` — Server connection config (hostname, port, SSL). Owns aliases, triggers, gags, and tickers.
- `Alias` — Input substitution rules.
- `Trigger` — Pattern-matched auto-responses with optional sound/color effects.
- `Gag` — Line suppression filters.
- `Ticker` — Periodic timed commands.

### UI Layer
- **Controllers/Client/** — Active MUD session: `SSClientViewController` handles the terminal view, `SSSessionLogger` records session transcripts, `SPLWorldTickerManager` runs tickers.
- **Controllers/Settings/** — World list, world editor, theme picker, sound picker, encoding picker.
- **Views/** — `SSMudView` terminal display, `SSGrowingTextView` input field, `SSTextTableView` scrollback.
- **Forms/** — QuickDialog/FXForms-based editors for aliases, triggers, gags, tickers, and world config.

### Key Dependencies (via CocoaPods)
- `CocoaAsyncSocket` — TCP socket library
- `libtelnet` — Telnet protocol primitives
- `JASidePanels` — Side panel navigation
- `TTTAttributedLabel` — Rich text display
- `Masonry` — Auto Layout DSL
- `ARAnalytics/HockeyApp` — Analytics (HockeyApp keys required via `cocoapods-keys`)

## Git

- **Main branch:** `trunk`
