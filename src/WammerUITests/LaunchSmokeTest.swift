import XCTest

/// Baseline smoke test for the WammerUITests target.
///
/// Proves the UI test target builds, the app launches under XCUIApplication,
/// and the host Wammer process reaches the foreground. Per-screen accessibility
/// audits live in separate test files (added in Phase 1 T2 / chainlink #49).
final class LaunchSmokeTest: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesToForeground() {
        let app = XCUIApplication.configuredForAudit(skipWelcomeModal: false)
        app.launch()
        XCTAssertEqual(app.state, .runningForeground, "App should reach the foreground after launch")
    }
}
