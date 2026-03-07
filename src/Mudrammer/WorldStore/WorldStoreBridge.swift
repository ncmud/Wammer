import Foundation
import UIKit

/// ObjC-visible wrapper around MUDWorld for use by ObjC code.
/// ObjC files import Wammer-Swift.h to access this type.
@objc(MUDWorldBridge)
@objcMembers
final class MUDWorldBridge: NSObject {
    private let swiftWorld: MUDWorld

    init(swiftWorld: MUDWorld) {
        self.swiftWorld = swiftWorld
    }

    var identifier: String { swiftWorld.identifier }
    var hostname: String { swiftWorld.hostname }
    var name: String { swiftWorld.name }
    var port: Int16 { swiftWorld.port }
    var isDefault: Bool { swiftWorld.isDefault }
    var isSecure: Bool { swiftWorld.isSecure }
    var connectCommand: String? { swiftWorld.connectCommand }
}

/// ObjC-visible bridge to WorldStore singleton.
@objc(WorldStoreBridge)
@objcMembers
final class WorldStoreBridge: NSObject {

    @objc static let didChangeNotification = NSNotification.Name.worldStoreDidChange

    @objc static func allWorlds() -> [MUDWorldBridge] {
        WorldStore.shared.worlds.map { MUDWorldBridge(swiftWorld: $0) }
    }

    @objc static func world(forIdentifier identifier: String) -> MUDWorldBridge? {
        guard let w = WorldStore.shared.world(forIdentifier: identifier) else { return nil }
        return MUDWorldBridge(swiftWorld: w)
    }

    @objc static func addWorld(hostname: String, name: String, port: Int16) {
        let w = MUDWorld(hostname: hostname, name: name, port: port)
        WorldStore.shared.addWorld(w)
    }

    @objc static func addEmptyWorld() -> String {
        let w = MUDWorld(port: 23)
        WorldStore.shared.addWorld(w)
        return w.identifier
    }

    @objc static func removeWorld(identifier: String) {
        guard let w = WorldStore.shared.world(forIdentifier: identifier) else { return }
        WorldStore.shared.removeWorld(w)
    }

    @objc static func setDefaultWorld(identifier: String) {
        let store = WorldStore.shared
        for (i, w) in store.worlds.enumerated() {
            if w.isDefault && w.identifier != identifier {
                store.worlds[i].isDefault = false
            }
            if w.identifier == identifier {
                store.worlds[i].isDefault = true
            }
        }
        store.save()
    }

    @objc static func defaultWorldIdentifier() -> String? {
        WorldStore.shared.worlds.first { $0.isDefault }?.identifier
    }

    @objc static func mudWorld(forIdentifier identifier: String) -> MUDWorld? {
        WorldStore.shared.world(forIdentifier: identifier)
    }

    @objc static func updateMUDWorld(_ world: MUDWorld) {
        WorldStore.shared.updateWorld(world)
    }

    @objc static func addMUDWorld(_ world: MUDWorld) {
        WorldStore.shared.addWorld(world)
    }

    @objc static func worldDescription(forIdentifier identifier: String) -> String? {
        WorldStore.shared.world(forIdentifier: identifier)?.worldDescription
    }

    @objc static func addTicker(toWorldIdentifier identifier: String, commands: String, interval: Int64, isEnabled: Bool) {
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return }
        let ticker = MUDTicker(interval: interval, commands: commands)
        ticker.isEnabled = isEnabled
        world.tickers.append(ticker)
        WorldStore.shared.updateWorld(world)
    }

    // MARK: - Ticker Access

    @objc static func tickers(forWorldIdentifier identifier: String) -> [MUDTickerBridge] {
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return [] }
        return world.tickers.filter { !$0.isHidden }.map { MUDTickerBridge(swiftTicker: $0) }
    }

    @objc static func ticker(forIdentifier tickerIdentifier: String, worldIdentifier: String) -> MUDTickerBridge? {
        guard let world = WorldStore.shared.world(forIdentifier: worldIdentifier) else { return nil }
        guard let ticker = world.tickers.first(where: { $0.identifier == tickerIdentifier }) else { return nil }
        return MUDTickerBridge(swiftTicker: ticker)
    }

    // MARK: - Record Editing

    @objc static func addTrigger(_ trigger: MUDTrigger, toWorldIdentifier identifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return }
        world.triggers.append(trigger)
        WorldStore.shared.updateWorld(world)
    }

    @objc static func addAlias(_ alias: MUDAlias, toWorldIdentifier identifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return }
        world.aliases.append(alias)
        WorldStore.shared.updateWorld(world)
    }

    @objc static func addGag(_ gag: MUDGag, toWorldIdentifier identifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return }
        world.gags.append(gag)
        WorldStore.shared.updateWorld(world)
    }

    @objc static func removeTrigger(identifier triggerIdentifier: String, fromWorldIdentifier worldIdentifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: worldIdentifier) else { return }
        world.triggers.removeAll { $0.identifier == triggerIdentifier }
        WorldStore.shared.updateWorld(world)
    }

    @objc static func removeAlias(identifier aliasIdentifier: String, fromWorldIdentifier worldIdentifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: worldIdentifier) else { return }
        world.aliases.removeAll { $0.identifier == aliasIdentifier }
        WorldStore.shared.updateWorld(world)
    }

    @objc static func removeGag(identifier gagIdentifier: String, fromWorldIdentifier worldIdentifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: worldIdentifier) else { return }
        world.gags.removeAll { $0.identifier == gagIdentifier }
        WorldStore.shared.updateWorld(world)
    }

    @objc static func removeTicker(identifier tickerIdentifier: String, fromWorldIdentifier worldIdentifier: String) {
        guard let world = WorldStore.shared.world(forIdentifier: worldIdentifier) else { return }
        world.tickers.removeAll { $0.identifier == tickerIdentifier }
        WorldStore.shared.updateWorld(world)
    }

    // MARK: - Alias / Gag / Trigger Matching

    @objc static func commandsIfMatchingAlias(forIdentifier identifier: String, input: String) -> [String]? {
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return nil }
        return world.commandsIfMatchingAlias(forInput: input)
    }

    @objc static func filteredIndexesByMatchingGags(forIdentifier identifier: String, lines: [Any]) -> IndexSet {
        let stringLines = lines.map { ($0 as? String) ?? "" }
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else {
            return IndexSet(integersIn: 0..<stringLines.count)
        }
        return world.filteredIndexesByMatchingGags(inLines: stringLines)
    }

    @objc static func runTriggers(forIdentifier identifier: String, lines: [Any]) -> MUDTriggerResultBridge? {
        let stringLines = lines.map { ($0 as? String) ?? "" }
        guard let world = WorldStore.shared.world(forIdentifier: identifier) else { return nil }
        let result = world.runTriggers(forLines: stringLines)
        return MUDTriggerResultBridge(result: result)
    }
}

/// ObjC-visible wrapper around MUDTicker for use by ticker manager.
@objc(MUDTickerBridge)
@objcMembers
final class MUDTickerBridge: NSObject {
    private let swiftTicker: MUDTicker

    init(swiftTicker: MUDTicker) {
        self.swiftTicker = swiftTicker
    }

    var identifier: String { swiftTicker.identifier }
    var isEnabled: Bool { swiftTicker.isEnabled }
    var interval: Int64 { swiftTicker.interval }
    var commands: String { swiftTicker.commands }
    var soundFileName: String? { swiftTicker.soundFileName }
}

/// ObjC-visible trigger result wrapper.
@objc(MUDTriggerResultBridge)
@objcMembers
final class MUDTriggerResultBridge: NSObject {
    let commands: [String]?
    let lineColors: [NSNumber: UIColor]?
    let soundName: String?

    init(result: MUDWorld.TriggerResult) {
        commands = result.commands.isEmpty ? nil : result.commands
        lineColors = result.colors.isEmpty ? nil : Dictionary(uniqueKeysWithValues:
            result.colors.map { (NSNumber(value: $0.key), $0.value) }
        )
        soundName = result.soundName
    }
}
