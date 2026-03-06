import Foundation

/// ObjC-visible wrapper around MUDWorld for use by ObjC code that cannot
/// import Wammer-Swift.h (header generation issue with Tuist/Xcode).
/// The matching WorldStoreBridge.h provides the ObjC declaration.
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
}
