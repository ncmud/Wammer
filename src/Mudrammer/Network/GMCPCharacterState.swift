import Foundation

@objc(GMCPCharacterState)
@objcMembers
final class GMCPCharacterState: NSObject {
    // Vitals
    @objc dynamic var hp: Int = 0
    @objc dynamic var maxHP: Int = 0
    @objc dynamic var mana: Int = 0
    @objc dynamic var maxMana: Int = 0
    @objc dynamic var moves: Int = 0
    @objc dynamic var maxMoves: Int = 0

    // Status
    @objc dynamic var level: Int = 0
    @objc dynamic var alignment: Int = 0
    @objc dynamic var gold: Int = 0
    @objc dynamic var tnl: Int = 0

    static let didUpdateNotification = Notification.Name("GMCPCharacterStateDidUpdate")

    func updateVitals(data: [String: Any]) {
        if let v = data["hp"] as? NSNumber { hp = v.intValue }
        if let v = data["maxhp"] as? NSNumber { maxHP = v.intValue }
        if let v = data["mana"] as? NSNumber { mana = v.intValue }
        if let v = data["maxmana"] as? NSNumber { maxMana = v.intValue }
        if let v = data["moves"] as? NSNumber { moves = v.intValue }
        if let v = data["maxmoves"] as? NSNumber { maxMoves = v.intValue }
        NotificationCenter.default.post(name: Self.didUpdateNotification, object: self)
    }

    func updateStatus(data: [String: Any]) {
        if let v = data["level"] as? NSNumber { level = v.intValue }
        if let v = data["align"] as? NSNumber { alignment = v.intValue }
        if let v = data["gold"] as? NSNumber { gold = v.intValue }
        if let v = data["tnl"] as? NSNumber { tnl = v.intValue }
        NotificationCenter.default.post(name: Self.didUpdateNotification, object: self)
    }

    func reset() {
        hp = 0; maxHP = 0; mana = 0; maxMana = 0; moves = 0; maxMoves = 0
        level = 0; alignment = 0; gold = 0; tnl = 0
    }
}
