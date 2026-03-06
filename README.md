# Wammer

[![CI](https://github.com/ncmud/Wammer/actions/workflows/ci.yml/badge.svg)](https://github.com/ncmud/Wammer/actions/workflows/ci.yml)

This is a fork of [MUDRammer](https://github.com/splinesoft/MUDRammer), a MUD client for iPhone and iPad originally created by [Jonathan Hersh](https://github.com/jhersh). MUDRammer was a fantastic piece of work — a polished, accessible, and thoughtfully designed MUD client that served the community well from its first App Store release in February 2013 through its removal in March 2025.

This fork aims to re-release the app under new branding with proper attribution to Jonathan and the original MUDRammer project. The codebase has been modernized to build with current tools and target iOS 26.

## What's Changed

- Replaced CocoaPods with vendored Swift Package Manager packages
- Replaced Xcode project with [Tuist](https://tuist.io) project generation
- Removed dead services (HockeyApp, UserVoice, IFTTTLaunchImage, cocoapods-keys)
- Replaced BlocksKit with native code
- Fixed removed/deprecated APIs (UIPopoverController, UIAlertView, UNUserNotificationCenter, etc.)
- 140 tests passing

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

[MUDs (Multi-User Dungeons)](https://en.wikipedia.org/wiki/MUD) are online multiplayer text-based games. Thousands of players today are on hundreds of MUDs in all manner of worlds: fantasy, absurdist, sci-fi, horror, and more. Many MUDs have been continuously online for decades. The app includes a `DefaultWorlds.plist` with a few interesting default worlds you can try, or you can add your own.

## License

MUDRammer's source code is available under the MIT license. See the `LICENSE` file for details.

Fonts, images, and sounds bundled with MUDRammer are licensed free for commercial use.

## Original Author

MUDRammer was designed and developed by [Jonathan Hersh](https://her.sh) starting in November 2012. It saw [34 App Store updates](https://github.com/splinesoft/MUDRammer/blob/master/AppStore/updates.txt) and was open-sourced in June 2015.
