import Foundation
import UIKit

/// The entry point for announcing incoming MUD text via VoiceOver.
///
/// Incoming lines from `SSMudView` are enqueued; the queue drains one line at
/// a time, waiting for the underlying `Announcer` to signal completion before
/// advancing. This serialization is what prevents VoiceOver from overlapping
/// two announcements when MUD output arrives in bursts.
///
/// This is the skeleton foundation of the Phase 2 speech-pipeline rebuild —
/// a drop-in replacement for the 2013 `SSSpeechSynthesizer` that adds a
/// testable `Announcer` seam and posts at iOS 17+ `UIAccessibilityPriority.low`
/// (via `UIAccessibilityAnnouncer`) so system-level announcements can take
/// precedence over streaming MUD text.
///
/// Later Phase 2 work, tracked in separate chainlink subissues, layers on:
///
/// - a pre-enqueue filter pipeline (blank lines, whitespace, ASCII art)
/// - prompt detection and filtering (addresses the "prompt-jumping" complaint
///   from real blind MUDRammer users in the 2025 AppleVis thread)
/// - user-configurable interrupt-vs-queue mode
/// - observable drop accounting
/// - user-typing behavior hook
/// - per-world speech configuration
@objc(MUDSpeechQueue)
@objcMembers
final class MUDSpeechQueue: NSObject {

    private let announcer: Announcer
    private var pending: [SpeechLine] = []
    private var isAnnouncing: Bool = false

    /// Designated initializer. Accepts a custom `Announcer` for unit tests.
    init(announcer: Announcer) {
        self.announcer = announcer
        super.init()
    }

    /// Convenience initializer used from `SSMudView` via the generated
    /// `Wammer-Swift.h` header. Defaults to the production
    /// `UIAccessibilityAnnouncer`, which posts real announcements to
    /// `UIAccessibility`.
    @objc override convenience init() {
        self.init(announcer: UIAccessibilityAnnouncer())
    }

    /// Enqueue a raw line of text for speech at the default `.low` priority.
    /// Matches `SSSpeechSynthesizer.enqueueLineForSpeaking:` so the SSMudView
    /// call site at `SSMudView.m:460` is a one-line type swap.
    @objc(enqueueLineForSpeaking:)
    func enqueueLineForSpeaking(_ text: String) {
        enqueue(SpeechLine(text: text))
    }

    /// Swift-side entry point. Enqueue a fully-formed `SpeechLine` with
    /// caller-specified priority and origin.
    func enqueue(_ line: SpeechLine) {
        guard !line.text.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pending.append(line)
            self.drainIfIdle()
        }
    }

    /// Clear every pending line that has not yet been handed to the announcer.
    /// The line currently being spoken (if any) will finish naturally — iOS
    /// does not expose a way to cancel an in-flight `.announcement`
    /// notification — but no further pending lines will be posted.
    ///
    /// Called from `SSMudView` on dealloc, `clearText`, `sendUserInput:`, and
    /// radial-control movement, so user actions stop the queue from piling
    /// more speech on top of whatever is currently playing.
    @objc func stopSpeaking() {
        DispatchQueue.main.async { [weak self] in
            self?.pending.removeAll()
        }
    }

    /// If the queue has pending lines and no announcement is in flight, pop
    /// the next one and hand it to the announcer. Called on main after each
    /// enqueue and after each completion callback.
    private func drainIfIdle() {
        guard !isAnnouncing, !pending.isEmpty else { return }

        isAnnouncing = true
        let next = pending.removeFirst()

        announcer.announce(next) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAnnouncing = false
                self.drainIfIdle()
            }
        }
    }
}
