import XCTest

/// Shared helpers for per-screen accessibility audits using
/// `XCUIApplication.performAccessibilityAudit(for:_:)`.
///
/// Each test supplies an allow-list of known failures. Every allow-list entry
/// carries a chainlink issue number that will eventually remove it; as those
/// issues are resolved, the corresponding entries go away and the audit becomes
/// a strict gate against regression.
enum AccessibilityAudit {

    /// A single allow-listed audit failure.
    ///
    /// An audit issue is suppressed when its `auditType` matches and its
    /// compact description contains `descriptionContains` (case-insensitive).
    /// A blank `descriptionContains` matches every issue of the given type.
    ///
    /// `issue` is a chainlink issue number that the entry is tracked against
    /// and which will eventually remove it. Use `issue: 0` as a sentinel for
    /// a by-design exclusion that is not expected to be fixed (for example,
    /// skipping contrast audits on screens that render user-chosen theme
    /// colors). By-design exclusions still require a meaningful `note`.
    struct AllowlistEntry {
        /// Chainlink issue number that will eventually remove this entry, or
        /// `0` for a by-design exclusion (see type doc comment).
        let issue: Int
        /// Accessibility audit type this entry allows.
        let auditType: XCUIAccessibilityAuditType
        /// Case-insensitive substring to match against the issue's compact
        /// description. Empty matches every issue of the given type.
        let descriptionContains: String
        /// Human-readable note explaining why the entry is here.
        let note: String

        init(
            issue: Int,
            auditType: XCUIAccessibilityAuditType,
            descriptionContains: String = "",
            note: String = ""
        ) {
            self.issue = issue
            self.auditType = auditType
            self.descriptionContains = descriptionContains
            self.note = note
        }

        func matches(_ auditIssue: XCUIAccessibilityAuditIssue) -> Bool {
            guard auditIssue.auditType == auditType else { return false }
            guard !descriptionContains.isEmpty else { return true }
            return auditIssue.compactDescription
                .localizedCaseInsensitiveContains(descriptionContains)
        }
    }

    /// Run an accessibility audit on the given app and suppress allow-listed failures.
    ///
    /// - Parameters:
    ///   - app: the `XCUIApplication` to audit.
    ///   - types: the audit types to run. Defaults to `.all`.
    ///   - allowlist: known failures to suppress, each tagged with a chainlink issue.
    /// - Throws: rethrows `performAccessibilityAudit` failures for any issue that
    ///   does not match an allow-list entry.
    static func run(
        on app: XCUIApplication,
        types: XCUIAccessibilityAuditType = .all,
        allowlist: [AllowlistEntry] = []
    ) throws {
        try app.performAccessibilityAudit(for: types) { issue in
            // Return `true` to ignore the issue, `false` to fail the test.
            for entry in allowlist where entry.matches(issue) {
                return true
            }
            return false
        }
    }
}
