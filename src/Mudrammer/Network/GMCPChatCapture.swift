import Foundation
import UIKit

/// In-memory buffer of chat lines captured from GMCP `Comm.Channel.*` packets.
///
/// Accepts two GMCP shapes and normalizes them:
/// - Standard / NCMUD: `Comm.Channel.Text` with `{ channel, talker, text }`.
/// - Aardwolf legacy: `comm.channel` (no sub-name) with `{ chan, player, msg }`.
///
/// Lines are pre-rendered to `SSAttributedLineGroup` on ingest using the current theme,
/// then stored in arrival order. The view controller subscribes to
/// `didCaptureChatNotification` for incremental updates and reads `capturedLines` on first
/// presentation.
@objc(GMCPChatCapture)
@objcMembers
final class GMCPChatCapture: NSObject {

    static let didCaptureChatNotification = Notification.Name("GMCPChatCaptureDidCaptureChat")
    static let didClearChatNotification = Notification.Name("GMCPChatCaptureDidClearChat")

    /// Key in didCaptureChatNotification userInfo carrying the newly-captured SSAttributedLineGroup.
    static let lineGroupUserInfoKey = "lineGroup"

    /// All captured lines in arrival order. Pre-rendered with timestamp prefix.
    private(set) var capturedLines: [SSAttributedLineGroup] = []

    /// True once at least one chat line has been captured this session.
    var hasReceivedChat: Bool { !capturedLines.isEmpty }

    private let ansiEngine: SSANSIEngine
    private let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    override init() {
        ansiEngine = SSANSIEngine()
        super.init()
        applyThemeDefaults()
    }

    /// Process a GMCP module payload. Returns true iff a chat line was captured.
    @discardableResult
    func ingest(module: String, data: [AnyHashable: Any]) -> Bool {
        let captured: CapturedChat?
        switch module.lowercased() {
        case "comm.channel.text":
            captured = parseStandard(data: data)
        case "comm.channel":
            captured = parseAardwolf(data: data)
        default:
            return false
        }
        guard let chat = captured else { return false }
        append(chat)
        return true
    }

    func clear() {
        guard !capturedLines.isEmpty else { return }
        capturedLines.removeAll()
        NotificationCenter.default.post(name: Self.didClearChatNotification, object: self)
    }

    /// Refresh ANSI engine theme defaults. Call after a theme change so subsequently captured
    /// lines render with the new defaults. Already-captured lines retain their original styling.
    func applyThemeDefaults() {
        if let color = SSThemes.sharedThemer().value(forThemeKey: kThemeFontColor) as? UIColor {
            ansiEngine.defaultTextColor = color
        }
    }

    // MARK: - Parsing

    private func parseStandard(data: [AnyHashable: Any]) -> CapturedChat? {
        guard let text = data["text"] as? String, !text.isEmpty else { return nil }
        let channel = (data["channel"] as? String ?? "").lowercased()
        let speaker = data["talker"] as? String
        return CapturedChat(timestamp: Date(), channel: channel, speaker: speaker, text: text)
    }

    private func parseAardwolf(data: [AnyHashable: Any]) -> CapturedChat? {
        guard let text = data["msg"] as? String, !text.isEmpty else { return nil }
        let channel = (data["chan"] as? String ?? "").lowercased()
        let speaker = data["player"] as? String
        return CapturedChat(timestamp: Date(), channel: channel, speaker: speaker, text: text)
    }

    // MARK: - Rendering

    private func append(_ chat: CapturedChat) {
        let group = render(chat)
        capturedLines.append(group)
        NotificationCenter.default.post(
            name: Self.didCaptureChatNotification,
            object: self,
            userInfo: [Self.lineGroupUserInfoKey: group]
        )
    }

    private func render(_ chat: CapturedChat) -> SSAttributedLineGroup {
        let parsed: SSAttributedLineGroup = ansiEngine.parseANSIString(chat.text) ?? SSAttributedLineGroup()
        let stamp = "[\(timestampFormatter.string(from: chat.timestamp))] "
        // Mirrors the NCMUD Mudlet decho colour "<200,150,0>" used for the timestamp prefix.
        let stampColor = UIColor(red: 200.0 / 255.0, green: 150.0 / 255.0, blue: 0.0, alpha: 1.0)
        let stampString = NSAttributedString(
            string: stamp,
            attributes: [.foregroundColor: stampColor]
        )
        let stamped = SSAttributedLineGroup(attributedString: stampString)!
        stamped.append(parsed)
        return stamped
    }
}

/// Normalized chat event before rendering. Kept Swift-only.
struct CapturedChat {
    let timestamp: Date
    /// Normalized lowercase channel name ("tell", "gossip", ...). Empty if the packet omitted it.
    let channel: String
    /// Player name when supplied; nil otherwise.
    let speaker: String?
    /// Raw ANSI-tagged text as received from the server.
    let text: String
}
