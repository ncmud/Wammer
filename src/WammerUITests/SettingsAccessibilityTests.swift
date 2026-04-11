import XCTest

/// Audits the settings screen reached from the client view's Settings bar button.
///
/// Starts from the client view (welcome modal skipped via `-InitialSetupComplete YES`),
/// taps the Settings bar button, waits for the modal navigation controller to settle,
/// then audits whatever is visible — the settings root (`SSSettingsViewController`).
///
/// Settings uses system colors rather than MUD theme colors, so contrast checks stay
/// strict here (unlike the client view, where contrast is by-design excluded).
final class SettingsAccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSettingsRootPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-InitialSetupComplete", "YES"]
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)

        // Tap the Settings bar button to open SSSettingsViewController modally.
        // The button's accessibilityLabel is NSLocalizedString(@"SETTINGS", nil)
        // which resolves to "Settings" in en.lproj.
        let settingsButton = app.buttons["Settings"].firstMatch
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 5),
            "Settings bar button should be present on the client view"
        )
        settingsButton.tap()

        // Give the modal presentation animation time to complete.
        // Settings is pushed inside a UINavigationController wrapper, so the
        // visible hierarchy changes from the client view to the settings list.
        Thread.sleep(forTimeInterval: 0.75)

        try AccessibilityAudit.run(
            on: app,
            allowlist: [
                // Allow-listed: Dynamic Type unsupported — tracked by chainlink #12.
                .init(
                    issue: 12,
                    auditType: .dynamicType,
                    note: "No Dynamic Type support project-wide; tracked by chainlink #12"
                ),
            ]
        )
    }
}
