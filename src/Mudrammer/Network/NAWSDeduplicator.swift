import Foundation

/// Tracks the last NAWS (cols, rows) that was sent so equivalent updates can
/// be suppressed before they hit the wire. Zero or negative dimensions are
/// always rejected.
struct NAWSDeduplicator {
    private var lastCols: Int = 0
    private var lastRows: Int = 0

    /// Returns true (and records the new values) when `(cols, rows)` differs
    /// from the previously-recorded send. Returns false when either value is
    /// non-positive or matches the previously-recorded send.
    mutating func shouldSend(cols: Int, rows: Int) -> Bool {
        guard cols > 0, rows > 0 else { return false }
        guard cols != lastCols || rows != lastRows else { return false }
        lastCols = cols
        lastRows = rows
        return true
    }

    mutating func reset() {
        lastCols = 0
        lastRows = 0
    }
}
