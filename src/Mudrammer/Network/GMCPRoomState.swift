import Foundation

@objc(GMCPRoomState)
@objcMembers
final class GMCPRoomState: NSObject {
    @objc dynamic var roomNumber: Int = 0
    @objc dynamic var exits: [String: NSNumber] = [:]

    static let didUpdateNotification = Notification.Name("GMCPRoomStateDidUpdate")

    func update(data: [String: Any]) {
        if let v = data["num"] as? NSNumber { roomNumber = v.intValue }
        if let exitData = data["exits"] as? [String: NSNumber] {
            exits = exitData
        }
        NotificationCenter.default.post(name: Self.didUpdateNotification, object: self)
    }

    func reset() {
        roomNumber = 0
        exits = [:]
    }
}
