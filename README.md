# Wammer

[![Build](https://github.com/ncmud/Wammer/actions/workflows/ci.yml/badge.svg)](https://github.com/ncmud/Wammer/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2026-blue)](https://developer.apple.com/ios/)
![It's dangerous!](https://img.shields.io/badge/You_are_likely_to_be_eaten_by_a-grue-red.svg)
[![Take this.](https://img.shields.io/badge/get-lamp-yellow.svg)](http://getlamp.com)

This is a fork of [MUDRammer](https://github.com/splinesoft/MUDRammer), a MUD client for iPhone and iPad originally created by [Jonathan Hersh](https://github.com/jhersh). MUDRammer was a fantastic piece of work — a polished, accessible, and thoughtfully designed MUD client that served the community well from its first App Store release in February 2013 through its removal in March 2025.

This fork aims to re-release the app under new branding with proper attribution to Jonathan and the original MUDRammer project. The codebase has been modernized to build with current tools and target iOS 26.

## Getting Started

You'll need Xcode 26+ and [Tuist](https://tuist.io).

```bash
tuist generate
```

Open the generated `Wammer.xcworkspace`, select the **Wammer** scheme, and build.

To run tests:

```bash
xcodebuild test -workspace Wammer.xcworkspace -scheme MRTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## About MUDs

[MUDs (Multi-User Dungeons)](https://en.wikipedia.org/wiki/MUD) are online multiplayer text-based games. Thousands of players today are on hundreds of MUDs in all manner of worlds: fantasy, absurdist, sci-fi, horror, and more. Many MUDs have been continuously online for decades. The app ships with a curated list of default worlds defined in `WorldStore.swift` to help new players get started, and you can add your own.

## Supported Protocols

Wammer connects over TCP with full telnet negotiation via [libtelnet](https://github.com/seanmiddleditch/libtelnet). The following MUD protocols are supported:

| Protocol | Description |
|----------|-------------|
| **ANSI color** | 16 and 256 color rendering with bold, underline, reverse, and strikethrough |
| **MCCP2** | Mud Client Compression Protocol v2 (zlib) for compressed data transfer |
| **MSSP** | Mud Server Status Protocol — displays server metadata when available |
| **GMCP** | Generic MUD Communication Protocol — out-of-band JSON messaging for character stats, room info, and audio |
| **NAWS** | Negotiate About Window Size — reports terminal dimensions to the server |
| **TTYPE** | Terminal Type negotiation (sends WAMMER, XTERM, ANSI) |
| **TLS/SSL** | Encrypted connections with per-world configuration |
| **Client.Media** | GMCP media package — downloads and plays server-triggered sound effects and music |

## License

MUDRammer's source code is available under the MIT license. See the `LICENSE` file for details.

Fonts, images, and sounds bundled with MUDRammer are licensed free for commercial use.

## About the Name

The original MUDRammer was named after a character belonging to one of Jonathan's Dutch mudding friends. When forking the project, we wanted to pay homage to that tradition. Wammer is named after my friend who got me into MUDding, whose first character was named "Wam."

## Original Author

MUDRammer was designed and developed by [Jonathan Hersh](https://her.sh) starting in November 2012. It saw [34 App Store updates](https://github.com/splinesoft/MUDRammer/blob/master/AppStore/updates.txt) and was open-sourced in June 2015.
