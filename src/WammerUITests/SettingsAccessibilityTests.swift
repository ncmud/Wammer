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
        let app = XCUIApplication.configuredForAudit(skipWelcomeModal: true)
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)

        // Tap the Settings bar button and wait for the settings root to settle.
        // `openSettings` uses the "Worlds" drill-down row as its post-tap
        // existence signal, replacing the previous fixed 0.75 s sleep.
        XCTAssertTrue(
            app.openSettings(),
            "Settings should open successfully"
        )

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
