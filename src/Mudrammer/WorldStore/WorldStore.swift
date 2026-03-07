import Foundation

extension NSNotification.Name {
    static let worldStoreDidChange = NSNotification.Name("WorldStoreDidChangeNotification")
}

@objc(WorldStore)
@objcMembers
final class WorldStore: NSObject {

    static let shared = WorldStore()

    private(set) var worlds: [MUDWorld] = []

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("worlds.json")
    }

    private override init() {
        super.init()
        load()
    }

    // MARK: - Persistence

    func load() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                worlds = try JSONDecoder.worldStore.decode([MUDWorld].self, from: data)
            } catch {
                NSLog("WorldStore: failed to load worlds.json: %@", error.localizedDescription)
                worlds = []
            }
        } else {
            worlds = Self.loadDefaultWorlds()
            save()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder.worldStore.encode(worlds)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("WorldStore: failed to save worlds.json: %@", error.localizedDescription)
        }
    }

    // MARK: - Accessors

    func world(forIdentifier identifier: String) -> MUDWorld? {
        worlds.first { $0.identifier == identifier }
    }

    // MARK: - Mutations

    func addWorld(_ world: MUDWorld) {
        worlds.append(world)
        save()
        postChangeNotification()
    }

    func removeWorld(_ world: MUDWorld) {
        worlds.removeAll { $0.identifier == world.identifier }
        save()
        postChangeNotification()
    }

    func updateWorld(_ world: MUDWorld) {
        if let idx = worlds.firstIndex(where: { $0.identifier == world.identifier }) {
            worlds[idx] = world
        }
        save()
        postChangeNotification()
    }

    // MARK: - Default Worlds

    private static func loadDefaultWorlds() -> [MUDWorld] {
        let worlds = [
            MUDWorld(hostname: "ncmud.org",                name: "NCMUD",                port: 9001, isSecure: true),
            MUDWorld(hostname: "nanvaent.org",             name: "Nanvaent",             port:   23),
            MUDWorld(hostname: "achaea.com",               name: "Achaea",               port:   23),
            MUDWorld(hostname: "valhalla.com",             name: "Valhalla",             port: 4242),
            MUDWorld(hostname: "tharel.net",               name: "Adventures Unlimited", port: 5005),
            MUDWorld(hostname: "aardmud.org",              name: "Aardwolf",             port: 4010),
            MUDWorld(hostname: "discworld.starturtle.net", name: "Discworld",            port:   23),
            MUDWorld(hostname: "lusternia.com",            name: "Lusternia",            port:   23),
            MUDWorld(hostname: "swmud.org",                name: "Star Wars MUD",        port: 6666),
            MUDWorld(hostname: "8bit.fansi.org",           name: "8bit MUSH",            port: 4201),
            MUDWorld(hostname: "furscape.com",             name: "Furscape",             port: 2001),
            MUDWorld(hostname: "ancient.anguish.org",      name: "Ancient Anguish",      port: 2222),
        ]
        worlds[0].isDefault = true
        return worlds
    }

    // MARK: - Notifications

    private func postChangeNotification() {
        NotificationCenter.default.post(name: .worldStoreDidChange, object: self)
    }
}

// MARK: - Coder Configuration

private extension JSONEncoder {
    static let worldStore: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

private extension JSONDecoder {
    static let worldStore: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
