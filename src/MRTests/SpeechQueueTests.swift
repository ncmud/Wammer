import Testing
import Foundation
import UIKit
@testable import Wammer

/// Unit tests for `MUDSpeechQueue` — the Phase 2 speech pipeline skeleton.
///
/// The tests use a `RecordingAnnouncer` that captures every `announce` call
/// and surfaces a manual `complete` operation, so each test can drive the
/// queue's drain loop without depending on the real `UIAccessibility`
/// subsystem (which is silent under tests / on a CI simulator anyway).
///
/// All tests run on `@MainActor` because the queue dispatches its internal
/// state mutations to `DispatchQueue.main`. The short `Task.sleep` calls
/// between enqueue and assertion give those main-queue blocks a chance to
/// execute before the test reads state.
@MainActor
struct SpeechQueueTests {

    /// Test double for `Announcer` that records every line handed to it and
    /// lets the test drive completion manually.
    final class RecordingAnnouncer: Announcer {
        private(set) var announced: [SpeechLine] = []
        private var pendingCompletions: [() -> Void] = []

        func announce(_ line: SpeechLine, completion: @escaping () -> Void) {
            announced.append(line)
            pendingCompletions.append(completion)
        }

        /// Simulate the system finishing the oldest pending announcement.
        func completeOldest() {
            guard !pendingCompletions.isEmpty else { return }
            pendingCompletions.removeFirst()()
        }
    }

    /// Brief yield so main-queue async blocks posted from the queue actually
    /// run before the test asserts. 10 ms is plenty for a same-runloop hop.
    private func flushMainQueue() async {
        try? await Task.sleep(nanoseconds: 10_000_000)
    }

    // MARK: - Input validation

    @Test func emptyTextIsDroppedAtEnqueue() async {
        let recorder = RecordingAnnouncer()
        let queue = MUDSpeechQueue(announcer: recorder)

        queue.enqueueLineForSpeaking("")
        queue.enqueue(SpeechLine(text: ""))

        await flushMainQueue()

        #expect(recorder.announced.isEmpty)
    }

    // MARK: - Forwarding

    @Test func nonEmptyLineReachesAnnouncer() async {
        let recorder = RecordingAnnouncer()
        let queue = MUDSpeechQueue(announcer: recorder)

        queue.enqueueLineForSpeaking("You are in the town square.")

        await flushMainQueue()

        #expect(recorder.announced.count == 1)
        #expect(recorder.announced.first?.text == "You are in the town square.")
    }

    @Test func objcEnqueueUsesLowPriorityAndServerOrigin() async {
        let recorder = RecordingAnnouncer()
        let queue = MUDSpeechQueue(announcer: recorder)

        queue.enqueueLineForSpeaking("A goblin arrives from the north.")

        await flushMainQueue()

        let line = try? #require(recorder.announced.first)
        #expect(line?.priority == .low)
        #expect(line?.origin == .server)
    }

    // MARK: - Drain ordering

    @Test func linesDrainInOrderAsCompletionsFire() async {
        let recorder = RecordingAnnouncer()
        let queue = MUDSpeechQueue(announcer: recorder)

        queue.enqueueLineForSpeaking("alpha")
        queue.enqueueLineForSpeaking("beta")
        queue.enqueueLineForSpeaking("gamma")

        // The queue should only hand the first line to the announcer until
        // that line completes — concurrent announcements would cause
        // VoiceOver to overlap them.
        await flushMainQueue()
        #expect(recorder.announced.map(\.text) == ["alpha"])

        recorder.completeOldest()
        await flushMainQueue()
        #expect(recorder.announced.map(\.text) == ["alpha", "beta"])

        recorder.completeOldest()
        await flushMainQueue()
        #expect(recorder.announced.map(\.text) == ["alpha", "beta", "gamma"])

        recorder.completeOldest()
        await flushMainQueue()
        #expect(recorder.announced.map(\.text) == ["alpha", "beta", "gamma"])
    }

    // MARK: - stopSpeaking

    @Test func stopSpeakingClearsPendingLinesNotYetAnnounced() async {
        let recorder = RecordingAnnouncer()
        let queue = MUDSpeechQueue(announcer: recorder)

        queue.enqueueLineForSpeaking("alpha")
        queue.enqueueLineForSpeaking("beta")
        queue.enqueueLineForSpeaking("gamma")

        await flushMainQueue()
        #expect(recorder.announced.map(\.text) == ["alpha"])

        // Drop everything that hasn't been handed to the announcer yet.
        queue.stopSpeaking()
        await flushMainQueue()

        // alpha is still "in flight" from the announcer's perspective;
        // completing it should NOT cause beta or gamma to speak, because
        // stopSpeaking removed them from the pending buffer.
        recorder.completeOldest()
        await flushMainQueue()

        #expect(recorder.announced.map(\.text) == ["alpha"])
    }

    @Test func enqueueAfterStopSpeakingWorksNormally() async {
        let recorder = RecordingAnnouncer()
        let queue = MUDSpeechQueue(announcer: recorder)

        queue.enqueueLineForSpeaking("alpha")
        await flushMainQueue()

        queue.stopSpeaking()
        recorder.completeOldest()
        await flushMainQueue()

        // stopSpeaking is not a latching gate — the next enqueue must still
        // be forwarded so user actions that call stopSpeaking don't muzzle
        // speech permanently.
        queue.enqueueLineForSpeaking("delta")
        await flushMainQueue()

        #expect(recorder.announced.map(\.text) == ["alpha", "delta"])
    }
}
