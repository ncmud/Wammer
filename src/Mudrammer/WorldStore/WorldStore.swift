import Foundation

@objc extension NSNotification.Name {
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
        guard let url = Bundle.main.url(forResource: "DefaultWorlds", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let array = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [[String: Any]]
        else { return [] }

        return array.map { dict in
            MUDWorld(
                hostname: dict["hostname"] as? String ?? "",
                name: dict["name"] as? String ?? "",
                port: Int16(dict["port"] as? Int ?? 0),
                isDefault: (dict["isDefault"] as? Int ?? 0) != 0
            )
        }
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
