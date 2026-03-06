import Foundation
import UIKit

// MARK: - MUDAlias

@objc(MUDAlias)
@objcMembers
final class MUDAlias: NSObject, Codable {
    var identifier: String
    var isEnabled: Bool
    var isHidden: Bool
    var lastModified: Date
    var name: String
    var commands: String

    override convenience init() {
        self.init(name: "", commands: "")
    }

    init(
        identifier: String = UUID().uuidString,
        isEnabled: Bool = true,
        isHidden: Bool = false,
        lastModified: Date = Date(),
        name: String = "",
        commands: String = ""
    ) {
        self.identifier = identifier
        self.isEnabled = isEnabled
        self.isHidden = isHidden
        self.lastModified = lastModified
        self.name = name
        self.commands = commands
    }
}

// MARK: - MUDTrigger

@objc enum MUDTriggerType: Int, Codable {
    case startOfLine = 0
    case lineContains = 1
}

@objc(MUDTrigger)
@objcMembers
final class MUDTrigger: NSObject, Codable {
    var identifier: String
    var isEnabled: Bool
    var isHidden: Bool
    var lastModified: Date
    var trigger: String
    var commands: String
    var soundFileName: String?
    var triggerType: MUDTriggerType
    var highlightColor: UIColor?
    var vibrate: Bool

    enum CodingKeys: String, CodingKey {
        case identifier, isEnabled, isHidden, lastModified
        case trigger, commands, soundFileName, triggerType
        case highlightColorHex, vibrate
    }

    override convenience init() {
        self.init(trigger: "", commands: "")
    }

    init(
        identifier: String = UUID().uuidString,
        isEnabled: Bool = true,
        isHidden: Bool = false,
        lastModified: Date = Date(),
        trigger: String = "",
        commands: String = "",
        soundFileName: String? = nil,
        triggerType: MUDTriggerType = .startOfLine,
        highlightColor: UIColor? = nil,
        vibrate: Bool = false
    ) {
        self.identifier = identifier
        self.isEnabled = isEnabled
        self.isHidden = isHidden
        self.lastModified = lastModified
        self.trigger = trigger
        self.commands = commands
        self.soundFileName = soundFileName
        self.triggerType = triggerType
        self.highlightColor = highlightColor
        self.vibrate = vibrate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(isHidden, forKey: .isHidden)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(trigger, forKey: .trigger)
        try container.encode(commands, forKey: .commands)
        try container.encodeIfPresent(soundFileName, forKey: .soundFileName)
        try container.encode(triggerType, forKey: .triggerType)
        try container.encodeIfPresent(highlightColor.map { Self.hexString(from: $0) }, forKey: .highlightColorHex)
        try container.encode(vibrate, forKey: .vibrate)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        trigger = try container.decode(String.self, forKey: .trigger)
        commands = try container.decode(String.self, forKey: .commands)
        soundFileName = try container.decodeIfPresent(String.self, forKey: .soundFileName)
        triggerType = try container.decode(MUDTriggerType.self, forKey: .triggerType)
        if let hex = try container.decodeIfPresent(String.self, forKey: .highlightColorHex) {
            highlightColor = Self.color(from: hex)
        }
        vibrate = try container.decode(Bool.self, forKey: .vibrate)
    }

    private static func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }

    private static func color(from hex: String) -> UIColor? {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        guard hexStr.count == 8, let value = UInt64(hexStr, radix: 16) else { return nil }
        let r = CGFloat((value >> 24) & 0xFF) / 255
        let g = CGFloat((value >> 16) & 0xFF) / 255
        let b = CGFloat((value >> 8) & 0xFF) / 255
        let a = CGFloat(value & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - MUDGag

@objc enum MUDGagType: Int, Codable {
    case startOfLine = 0
    case lineContains = 1
    case lineEquals = 2
}

@objc(MUDGag)
@objcMembers
final class MUDGag: NSObject, Codable {
    var identifier: String
    var isEnabled: Bool
    var isHidden: Bool
    var lastModified: Date
    var gagType: MUDGagType
    var gag: String

    override convenience init() {
        self.init(gag: "")
    }

    init(
        identifier: String = UUID().uuidString,
        isEnabled: Bool = true,
        isHidden: Bool = false,
        lastModified: Date = Date(),
        gagType: MUDGagType = .startOfLine,
        gag: String = ""
    ) {
        self.identifier = identifier
        self.isEnabled = isEnabled
        self.isHidden = isHidden
        self.lastModified = lastModified
        self.gagType = gagType
        self.gag = gag
    }
}

// MARK: - MUDTicker

@objc(MUDTicker)
@objcMembers
final class MUDTicker: NSObject, Codable {
    var identifier: String
    var isEnabled: Bool
    var isHidden: Bool
    var lastModified: Date
    var interval: Int64
    var commands: String
    var soundFileName: String?

    override convenience init() {
        self.init(interval: 0, commands: "")
    }

    init(
        identifier: String = UUID().uuidString,
        isEnabled: Bool = true,
        isHidden: Bool = false,
        lastModified: Date = Date(),
        interval: Int64 = 0,
        commands: String = "",
        soundFileName: String? = nil
    ) {
        self.identifier = identifier
        self.isEnabled = isEnabled
        self.isHidden = isHidden
        self.lastModified = lastModified
        self.interval = interval
        self.commands = commands
        self.soundFileName = soundFileName
    }
}

// MARK: - MUDWorld

@objc(MUDWorld)
@objcMembers
final class MUDWorld: NSObject, Codable {
    var identifier: String
    var isHidden: Bool
    var lastModified: Date
    var hostname: String
    var name: String
    var port: Int16
    var isDefault: Bool
    var isSecure: Bool
    var connectCommand: String?
    var aliases: [MUDAlias]
    var triggers: [MUDTrigger]
    var gags: [MUDGag]
    var tickers: [MUDTicker]

    override convenience init() {
        self.init(hostname: "", name: "", port: 0)
    }

    init(
        identifier: String = UUID().uuidString,
        isHidden: Bool = false,
        lastModified: Date = Date(),
        hostname: String = "",
        name: String = "",
        port: Int16 = 0,
        isDefault: Bool = false,
        isSecure: Bool = false,
        connectCommand: String? = nil,
        aliases: [MUDAlias] = [],
        triggers: [MUDTrigger] = [],
        gags: [MUDGag] = [],
        tickers: [MUDTicker] = []
    ) {
        self.identifier = identifier
        self.isHidden = isHidden
        self.lastModified = lastModified
        self.hostname = hostname
        self.name = name
        self.port = port
        self.isDefault = isDefault
        self.isSecure = isSecure
        self.connectCommand = connectCommand
        self.aliases = aliases
        self.triggers = triggers
        self.gags = gags
        self.tickers = tickers
    }
}
