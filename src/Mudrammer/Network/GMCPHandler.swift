import Foundation

@objc(GMCPHandler)
@objcMembers
final class GMCPHandler: NSObject {
    let characterState = GMCPCharacterState()
    let roomState = GMCPRoomState()
    let chatCapture = GMCPChatCapture()
    private let mediaManager = GMCPMediaManager()

    /// Set the MUD server hostname so downloaded media can be attributed to the correct server.
    var serverHostname: String? {
        didSet { mediaManager.serverHostname = serverHostname }
    }

    /// Display name for the world (used as "artist" in Now Playing).
    var worldName: String? {
        didSet { mediaManager.worldName = worldName }
    }

    /// When true, GMCP server music is ignored and ambient keeps playing.
    var overrideGameMusic: Bool {
        get { mediaManager.overrideGameMusic }
        set { mediaManager.overrideGameMusic = newValue }
    }

    /// Whether any music (ambient or server) is currently playing.
    var isMusicPlaying: Bool { mediaManager.isMusicPlaying }

    /// Whether any music (ambient or server) exists but is paused.
    var isMusicPaused: Bool { mediaManager.isMusicPaused }

    /// Pause all active music (ambient and/or server).
    func pauseMusic() { mediaManager.pauseMusic() }

    /// Resume paused music (ambient and/or server).
    func resumeMusic() { mediaManager.resumeMusic() }

    /// Stop all music (ambient and server). Sounds are unaffected.
    func stopMusic() { mediaManager.stopMusic() }

    /// Start looping ambient music from a music library relative path.
    func startAmbient(relativePath: String) {
        mediaManager.startAmbient(relativePath: relativePath)
    }

    func handleModule(_ module: String, data: [String: Any]) {
        NSLog("GMCP [%@] %@", module, data as NSDictionary)

        switch module.lowercased() {
        case "char.vitals":
            characterState.updateVitals(data: data)
        case "char.status":
            characterState.updateStatus(data: data)
        case "room.info":
            roomState.update(data: data)
        case "client.media.play":
            mediaManager.play(data: data)
        case "client.media.stop":
            mediaManager.stop(data: data)
        case "comm.channel.text", "comm.channel":
            chatCapture.ingest(module: module, data: data)
        default:
            NSLog("GMCP unhandled module: %@", module)
        }
    }

    func reset() {
        characterState.reset()
        roomState.reset()
        mediaManager.stopAll()
    }
}
