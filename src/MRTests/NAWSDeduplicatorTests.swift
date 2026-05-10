import Testing
@testable import Wammer

@Suite struct NAWSDeduplicatorTests {

    @Test func firstSendPasses() {
        var dedup = NAWSDeduplicator()
        let result = dedup.shouldSend(cols: 80, rows: 24)
        #expect(result)
    }

    @Test func duplicateSuppressed() {
        var dedup = NAWSDeduplicator()
        _ = dedup.shouldSend(cols: 80, rows: 24)
        let second = dedup.shouldSend(cols: 80, rows: 24)
        #expect(!second)
    }

    @Test func colsChangedAllowed() {
        var dedup = NAWSDeduplicator()
        _ = dedup.shouldSend(cols: 80, rows: 24)
        let second = dedup.shouldSend(cols: 100, rows: 24)
        #expect(second)
    }

    @Test func rowsChangedAllowed() {
        var dedup = NAWSDeduplicator()
        _ = dedup.shouldSend(cols: 80, rows: 24)
        let second = dedup.shouldSend(cols: 80, rows: 50)
        #expect(second)
    }

    @Test func resetClearsState() {
        var dedup = NAWSDeduplicator()
        _ = dedup.shouldSend(cols: 80, rows: 24)
        dedup.reset()
        let after = dedup.shouldSend(cols: 80, rows: 24)
        #expect(after)
    }

    @Test func zeroColsRejected() {
        var dedup = NAWSDeduplicator()
        let result = dedup.shouldSend(cols: 0, rows: 24)
        #expect(!result)
    }

    @Test func zeroRowsRejected() {
        var dedup = NAWSDeduplicator()
        let result = dedup.shouldSend(cols: 80, rows: 0)
        #expect(!result)
    }

    @Test func negativeRejected() {
        var dedup = NAWSDeduplicator()
        let negCols = dedup.shouldSend(cols: -1, rows: 24)
        let negRows = dedup.shouldSend(cols: 80, rows: -1)
        #expect(!negCols)
        #expect(!negRows)
    }

    @Test func rejectedSendDoesNotPoisonState() {
        var dedup = NAWSDeduplicator()
        _ = dedup.shouldSend(cols: 0, rows: 24)
        // First valid send should still pass.
        let valid = dedup.shouldSend(cols: 80, rows: 24)
        #expect(valid)
    }
}
