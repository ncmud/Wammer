import Foundation

@objc(GMCPHandler)
@objcMembers
final class GMCPHandler: NSObject {
    static let shared = GMCPHandler()

    let characterState = GMCPCharacterState()
    let roomState = GMCPRoomState()
    private let mediaManager = GMCPMediaManager()

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
