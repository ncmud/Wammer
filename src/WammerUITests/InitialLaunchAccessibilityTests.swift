import XCTest

/// Audits the screen that appears immediately after the app launches.
///
/// `WammerSceneDelegate` installs a root view controller (typically the client
/// view with a default world, or the world list on first launch). The failures
/// this audit surfaces become seeds for new chainlink issues or allow-list entries
/// tagged against existing ones.
final class InitialLaunchAccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testInitialScreenPassesAccessibilityAudit() throws {
        let app = XCUIApplication.configuredForAudit(skipWelcomeModal: false)
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)

        try AccessibilityAudit.run(
            on: app,
            allowlist: [
                // Allow-listed: Dynamic Type unsupported — tracked by chainlink #12.
                // The first-launch welcome screen uses fixed-point fonts; same pattern
                // across the rest of the UI. Remove this entry once #12 is complete.
                .init(
                    issue: 12,
                    auditType: .dynamicType,
                    note: "Wammer has zero Dynamic Type support; tracked by chainlink #12"
                ),
            ]
        )
    }
}
