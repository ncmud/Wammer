# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

### Fixed
- Fix crash in itemWithAttributedString: on empty string (#57)
- Fix libtelnet missing HAVE_ZLIB define causing MCCP2 gibberish (#56)

### Changed
- Configure test target for modern simulator (#49)
- Fix test code for API changes (#48)
- Verify Core Data / MagicalRecord compatibility (#46)
- Fix SPM module imports and umbrella headers for successful build (#55)
- Replace all BlocksKit usage with native code (#51)
- Update deprecated color APIs (#47)
- Fix dispatch queue priorities (#45)
- Fix appearanceWhenContainedIn: calls (#44)
- Fix status bar APIs (#43)
- Migrate to UNUserNotificationCenter (#42)
- Replace UIPopoverController (#41)
- Replace UIAlertView/UIActionSheet with UIAlertController (#40)
- Remove cocoapods-keys references (#39)
- Remove IFTTTLaunchImage (#38)
- Remove UserVoice integration (#37)
- Remove HockeyApp/ARAnalytics integration (#36)
- Create LaunchScreen.storyboard (#53)
- Generate or recreate SPLImagesCatalog (#52)
- Set up Tuist project (#35)
- Delete src/Pods/ directory (#2)
- Vendor MagicalRecord (#50)
- Vendor OCMock (#34)
- Vendor Expecta (#33)
- Vendor SPLUserActivity (#31)
- Vendor SSApplication (#30)
- Vendor SSOperations (#29)
- Vendor SSDataSources (#28)
- Vendor SSAccessibility (#27)
- Vendor SPLCore (#26)
- Vendor FXForms (#25)
- Vendor QuickDialog (#24)
- Vendor VTAcknowledgementsViewController (#23)
- Vendor TOWebViewController (#22)
- Vendor JTSImageViewController (#21)
- Vendor DAKeyboardControl (#20)
- Vendor JSQSystemSoundPlayer (#19)
- Vendor Masonry (#18)
- Vendor JASidePanels (#17)
- Vendor TTTAttributedLabel (#16)
- Vendor MyLilTimer (#15)
- Vendor OSCache (#14)
- Vendor KVOController (#13)
- Vendor SAMRateLimit (#12)
- Vendor libtelnet (#11)
- Vendor CocoaAsyncSocket (#10)
- Vendor test dependencies (#9)
- Vendor Splinesoft dependencies (#8)
- Vendor form dependencies (#7)
- Vendor UI dependencies (#6)
- Vendor engine dependencies (#5)
- Vendor networking dependencies (#4)
- Delete FauxPas config (#3)
- Delete dead build files (#1)
- Vendor SSMagicManagedObject (#32)
