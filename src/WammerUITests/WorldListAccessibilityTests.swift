import XCTest

/// Audits the world list screen reached via Settings → Worlds.
///
/// Navigation: welcome skipped via `-InitialSetupComplete YES` → tap Settings
/// bar button → settings modal settles → tap "Worlds" row → world list (an
/// `SSWorldListViewController` instance) is pushed onto the settings nav stack.
///
/// The plan's long-form scope for this file also covers the world editor and
/// the alias / trigger / gag / ticker form editors. Those are add-on test
/// methods that will land as separate PRs once the world list baseline is green.
final class WorldListAccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testWorldListPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-InitialSetupComplete", "YES"]
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)

        // Settings is modal and wraps its content in a nav controller.
        let settingsButton = app.buttons["Settings"].firstMatch
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 5),
            "Settings bar button should be present on the client view"
        )
        settingsButton.tap()
        Thread.sleep(forTimeInterval: 0.75)

        // Drill into the Worlds row. Label is NSLocalizedString(@"WORLDS", …)
        // which resolves to "Worlds" in en.lproj.
        let worldsCell = app.cells.staticTexts["Worlds"].firstMatch
        XCTAssertTrue(
            worldsCell.waitForExistence(timeout: 3),
            "Worlds row should be present in the settings list"
        )
        worldsCell.tap()
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
