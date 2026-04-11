import XCTest

/// Audits the main client view — the MUD terminal, input bar, directional pad,
/// accessory toolbar, and top bar buttons — in its disconnected state.
///
/// Launch argument `-InitialSetupComplete YES` skips the first-launch welcome modal
/// (`ClientContainer.swift:85`). No network connection is made; the default world is
/// present but not auto-connected when welcome is bypassed, so the audit reflects the
/// offline, disconnected state of the client view.
final class ClientViewAccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDisconnectedClientViewPassesAccessibilityAudit() throws {
        let app = XCUIApplication.configuredForAudit(skipWelcomeModal: true)
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)

        try AccessibilityAudit.run(
            on: app,
            allowlist: [
                // By-design exclusion: MUD clients render user-chosen theme colors
                // (traditional amber-on-black, bright ANSI foregrounds on dark
                // backgrounds, etc.). These are deliberate aesthetic choices by
                // the player, not accessibility failures — contrast ratios on
                // this screen are the player's call, not ours. If we ever want
                // per-theme contrast checking we'll do it separately.
                .init(
                    issue: 0,
                    auditType: .contrast,
                    note: "MUD theme colors are user-chosen; contrast checks N/A"
                ),
                // Allow-listed: Dynamic Type unsupported — tracked by chainlink #12.
                // Wammer uses fixed-point fonts everywhere. Remove once #12 lands.
                .init(
                    issue: 12,
                    auditType: .dynamicType,
                    note: "No Dynamic Type support project-wide; tracked by chainlink #12"
                ),
            ]
        )
    }
}
