import Foundation

@objc(GMCPHandler)
@objcMembers
final class GMCPHandler: NSObject {
    static let shared = GMCPHandler()

    let characterState = GMCPCharacterState()
    let roomState = GMCPRoomState()

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
            NSLog("GMCP MEDIA PLAY: name=%@ type=%@ url=%@ volume=%@ loops=%@",
                  data["name"] as? String ?? "(none)",
                  data["type"] as? String ?? "(none)",
                  data["url"] as? String ?? "(none)",
                  String(describing: data["volume"]),
                  String(describing: data["loops"]))
        case "client.media.stop":
            NSLog("GMCP MEDIA STOP: type=%@", data["type"] as? String ?? "(all)")
        default:
            NSLog("GMCP unhandled module: %@", module)
        }
    }

    func reset() {
        characterState.reset()
        roomState.reset()
    }
}
