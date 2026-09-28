import Foundation
import UIKit

/// Abstracts the final "post this line to VoiceOver" step so the speech
/// queue can be unit-tested without touching the real `UIAccessibility`
/// subsystem.
///
/// Implementations must invoke `completion` exactly once, regardless of
/// whether the line was actually spoken. The queue relies on that callback
/// to advance to the next line, so a missing completion would stall the
/// pipeline.
protocol Announcer: AnyObject {

    /// Post `line` to the underlying speech channel.
    ///
    /// - Parameters:
    ///   - line: the line to speak.
    ///   - completion: called exactly once when the announcer is finished
    ///     handling `line` — either because VoiceOver finished speaking it,
    ///     because the line was rejected (empty text, VoiceOver off), or
    ///     because a timeout elapsed without the system signalling
    ///     completion.
    func announce(_ line: SpeechLine, completion: @escaping () -> Void)
}

/// Production `Announcer` that posts to `UIAccessibility`.
///
/// Builds an `NSAttributedString` carrying both
/// `accessibilitySpeechAnnouncementPriority` and
/// `accessibilitySpeechQueueAnnouncement` so the iOS 17+ priority system
/// handles queueing behind existing speech. Observes
/// `UIAccessibility.announcementDidFinishNotification` to drive the
/// completion callback, with a timeout fallback for the case where the
/// system never fires the notification (which the 2013 `SSSpeechSynthesizer`
/// documented as a real occurrence under certain audio conditions).
final class UIAccessibilityAnnouncer: NSObject, Announcer {

    /// Seconds to wait for `announcementDidFinishNotification` before giving
    /// up on the current announcement and proceeding with the next one. Set
    /// to `0` to disable the timeout. Defaults to 16 seconds — matching the
    /// value `SSMudView` historically set on `SSSpeechSynthesizer`.
    let timeoutDelay: TimeInterval

    private var pendingText: String?
    private var pendingCompletion: (() -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?

    init(timeoutDelay: TimeInterval = 16.0) {
        self.timeoutDelay = timeoutDelay
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(announcementDidFinish(_:)),
            name: UIAccessibility.announcementDidFinishNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timeoutWorkItem?.cancel()
    }

    func announce(_ line: SpeechLine, completion: @escaping () -> Void) {
        // If a previous announcement was still pending when a new one
        // arrives, release the previous completion first so the queue can
        // track state correctly.
        firePendingCompletion()

        guard !line.text.isEmpty else {
            completion()
            return
        }
        guard UIAccessibility.isVoiceOverRunning else {
            completion()
            return
        }

        pendingText = line.text
        pendingCompletion = completion

        let attributed = NSAttributedString(
            string: line.text,
            attributes: [
                .accessibilitySpeechAnnouncementPriority: line.priority,
                .accessibilitySpeechQueueAnnouncement: true,
            ]
        )
        UIAccessibility.post(notification: .announcement, argument: attributed)

        if timeoutDelay > 0 {
            let work = DispatchWorkItem { [weak self] in
                self?.firePendingCompletion()
            }
            timeoutWorkItem = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + timeoutDelay,
                execute: work
            )
        }
    }

    @objc private func announcementDidFinish(_ note: Notification) {
        // The did-finish notification can also fire for non-announcement
        // audio events (mute switch, etc.). Only fire our completion if the
        // string in the userInfo matches what we posted.
        guard let userInfo = note.userInfo,
              let spokenText = userInfo[UIAccessibility.announcementStringValueUserInfoKey] as? String,
              spokenText == pendingText
        else {
            return
        }
        firePendingCompletion()
    }

    private func firePendingCompletion() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        pendingText = nil
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?()
    }
}
