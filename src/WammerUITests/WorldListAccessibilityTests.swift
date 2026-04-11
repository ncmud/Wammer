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
        let app = XCUIApplication.configuredForAudit(skipWelcomeModal: true)
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)

        // Open settings. `openSettings` also waits for the "Worlds" drill-down
        // row to appear — which is exactly the row we're about to tap, so the
        // wait does double duty here.
        XCTAssertTrue(
            app.openSettings(),
            "Settings should open successfully"
        )

        // Drill into the Worlds row. Label is NSLocalizedString(@"WORLDS", …)
        // which resolves to "Worlds" in en.lproj (locale pinned above).
        app.cells.staticTexts["Worlds"].firstMatch.tap()

        // Wait for the world list to settle, detected by the "New World" add
        // bar button (rightBarButtonItem on SSWorldListViewController) becoming
        // existent. This button is unique to the world list — unlike "Worlds"
        // itself, which is reused for the settings drill-down row.
        XCTAssertTrue(
            app.buttons["New World"].firstMatch.waitForExistence(timeout: 3),
            "World list should settle after tapping Worlds"
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
