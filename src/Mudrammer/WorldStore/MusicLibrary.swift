import Foundation

struct MusicTrack: Codable, Equatable {
    /// Relative path within the GMCPMedia cache directory (e.g., "ncmud.net/music/tavern.mp3").
    let relativePath: String
    /// The hostname of the server that originally played this track.
    let hostname: String
    /// GMCP type: "music" or "sound".
    let type: String
    /// The GMCP name field (e.g., "music/tavern.mp3").
    let name: String

    /// The folder components from the GMCP name, excluding the filename.
    /// e.g., "music/ambient/tavern.mp3" → ["music", "ambient"]
    var folderPath: [String] {
        let components = name.components(separatedBy: "/").dropLast()
        return Array(components)
    }

    /// Just the filename.
    var filename: String {
        (name as NSString).lastPathComponent
    }
}

@objc(MusicLibrary)
@objcMembers
final class MusicLibrary: NSObject {

    static let shared = MusicLibrary()

    private(set) var tracks: [MusicTrack] = []

    private let cacheBaseURL: URL
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("musicLibrary.json")
    }

    private override init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheBaseURL = caches.appendingPathComponent("GMCPMedia", isDirectory: true)
        super.init()
        load()
        pruneDeletedFiles()
        indexCacheDirectory()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            tracks = try JSONDecoder().decode([MusicTrack].self, from: data)
        } catch {
            NSLog("MusicLibrary: failed to load: %@", error.localizedDescription)
            tracks = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(tracks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("MusicLibrary: failed to save: %@", error.localizedDescription)
        }
    }

    /// Remove entries whose cached files no longer exist on disk.
    private func pruneDeletedFiles() {
        let before = tracks.count
        tracks.removeAll { !FileManager.default.fileExists(atPath: fileURL(for: $0).path) }
        if tracks.count != before {
            NSLog("MusicLibrary: pruned %d stale entries", before - tracks.count)
            save()
        }
    }

    /// Scan the GMCPMedia cache directory and register any files not already tracked.
    private func indexCacheDirectory() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: cacheBaseURL.path) else { return }

        guard let enumerator = fm.enumerator(
            at: cacheBaseURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var added = 0
        while let fileURL = enumerator.nextObject() as? URL {
            guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else {
                continue
            }

            let relativePath = fileURL.path
                .replacingOccurrences(of: cacheBaseURL.path + "/", with: "")
            guard !tracks.contains(where: { $0.relativePath == relativePath }) else {
                continue
            }

            let components = relativePath.components(separatedBy: "/")
            guard components.count >= 2 else { continue }

            let hostname = components[0]
            // The "name" is everything after the hostname (the GMCP name field).
            let name = components.dropFirst().joined(separator: "/")
            // Infer type from path — if name starts with "music" or "song", treat as music.
            let nameLower = name.lowercased()
            let type = nameLower.hasPrefix("music") || nameLower.hasPrefix("song") ? "music" : "sound"

            let track = MusicTrack(relativePath: relativePath, hostname: hostname, type: type, name: name)
            tracks.append(track)
            added += 1
        }

        if added > 0 {
            NSLog("MusicLibrary: indexed %d files from cache", added)
            save()
        }
    }

    // MARK: - Adding Tracks

    /// Register a track that was just downloaded by GMCPMediaManager.
    /// Deduplicates by relativePath; updates type if the server provides a different one.
    func addTrack(hostname: String, name: String, type: String, baseURL: URL) {
        let relativePath = Self.buildRelativePath(hostname: hostname, name: name, baseURL: baseURL)
        if let idx = tracks.firstIndex(where: { $0.relativePath == relativePath }) {
            if tracks[idx].type != type {
                tracks[idx] = MusicTrack(relativePath: relativePath, hostname: hostname, type: type, name: name)
                save()
            }
            return
        }

        let track = MusicTrack(relativePath: relativePath, hostname: hostname, type: type, name: name)
        tracks.append(track)
        save()
        NSLog("MusicLibrary: added %@ from %@", name, hostname)
    }

    // MARK: - Queries

    /// All unique hostnames that have contributed tracks.
    var hostnames: [String] {
        Array(Set(tracks.map(\.hostname))).sorted()
    }

    /// Tracks from a specific hostname.
    func tracks(forHostname hostname: String) -> [MusicTrack] {
        tracks.filter { $0.hostname == hostname }
    }

    /// Music tracks only (excludes sound effects).
    var musicTracks: [MusicTrack] {
        tracks.filter { $0.type == "music" }
    }

    /// Find a track by its relative path.
    func track(forRelativePath path: String) -> MusicTrack? {
        tracks.first { $0.relativePath == path }
    }

    // MARK: - File Access

    /// Absolute file URL for a track.
    func fileURL(for track: MusicTrack) -> URL {
        cacheBaseURL.appendingPathComponent(track.relativePath)
    }

    // MARK: - ObjC Helpers

    /// Returns the display filename for a track's relative path, or nil if not found.
    @objc func displayName(forRelativePath path: String) -> String? {
        track(forRelativePath: path)?.filename
    }

    /// Returns music tracks as an array of dictionaries for ObjC consumption.
    /// Each dict has keys: "relativePath", "hostname", "filename", "type".
    @objc var musicTrackDictionaries: [[String: String]] {
        musicTracks.map {
            [
                "relativePath": $0.relativePath,
                "hostname": $0.hostname,
                "filename": $0.filename,
                "type": $0.type,
            ]
        }
    }

    // MARK: - Path Building

    /// Build the relative path within GMCPMedia/ for a track.
    /// Mirrors the logic in GMCPMediaManager.cachePath(baseURL:name:).
    static func buildRelativePath(hostname: String, name: String, baseURL: URL) -> String {
        var components: [String] = []
        components.append(hostname)
        let basePath = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !basePath.isEmpty { components.append(basePath) }
        components.append(name)
        return components.joined(separator: "/")
    }
}
