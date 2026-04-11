import Foundation
import UIKit

/// A single line of text queued for VoiceOver announcement, with the metadata
/// the speech pipeline uses to decide priority and (in later subissues)
/// filtering and routing.
///
/// This is the foundation type for the Phase 2 speech-pipeline rebuild. Only
/// `text` is load-bearing in this skeleton; `priority` and `origin` are
/// present so follow-up work (filter pipeline, prompt detection, interrupt-
/// mode configuration) can populate them without reshaping the type.
struct SpeechLine: Equatable {

    /// The raw text to speak.
    let text: String

    /// The iOS 17+ accessibility priority at which to post the announcement.
    ///
    /// Defaults to `.low`: MUD server output should queue behind any currently
    /// speaking VoiceOver utterance and yield to higher-priority system or
    /// user announcements. User-defined triggers may later elevate specific
    /// lines to `.default` or `.high`.
    let priority: UIAccessibilityPriority

    /// Where this line entered the pipeline. Later filter and prompt-detection
    /// work keys off this to make per-origin decisions (for example, always
    /// suppressing `.prompt` lines from speech while still rendering them in
    /// the terminal view).
    enum Origin: Equatable {
        /// Raw line from the MUD socket.
        case server
        /// A MUD prompt line (HP/MP/room). Typically filtered from speech.
        case prompt
        /// A line that matched a user-defined trigger or alias.
        case trigger
        /// An app-generated line (connect, disconnect, error banner).
        case system
    }

    let origin: Origin

    init(
        text: String,
        priority: UIAccessibilityPriority = .low,
        origin: Origin = .server
    ) {
        self.text = text
        self.priority = priority
        self.origin = origin
    }
}
