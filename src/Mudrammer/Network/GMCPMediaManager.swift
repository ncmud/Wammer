import AVFoundation
import Foundation

final class GMCPMediaManager {
    private var musicPlayer: AVAudioPlayer?
    private var soundPlayer: AVAudioPlayer?
    private var musicPriority: Int = 0
    private var soundPriority: Int = 0
    private let cacheDirectory: URL
    private let session: URLSession

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("GMCPMedia", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)

        configureAudioSession()
    }

    private func configureAudioSession() {
        #if !targetEnvironment(macCatalyst)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        } catch {
            NSLog("GMCP Media: failed to configure audio session: %@", error.localizedDescription)
        }
        #endif
    }

    /// Build the cache path for a sound file, namespaced by server URL.
    /// e.g. `GMCPMedia/ncmud.net/sounds/NC/backstab.wav`
    /// This mirrors the URL structure so you can reconstruct the full URL from the path.
    func cachePath(baseURL: URL, name: String) -> URL {
        // Use host + path from the base URL as the namespace directory
        // e.g. https://ncmud.net/sounds/ → "ncmud.net/sounds"
        var components: [String] = []
        if let host = baseURL.host { components.append(host) }
        let basePath = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !basePath.isEmpty { components.append(basePath) }
        components.append(name)

        var result = cacheDirectory
        for component in components {
            result = result.appendingPathComponent(component)
        }
        return result
    }

    func play(data: [String: Any]) {
        guard let name = data["name"] as? String, !name.isEmpty else {
            NSLog("GMCP Media: play missing name")
            return
        }
        guard !name.contains("..") else {
            NSLog("GMCP Media: rejecting name with path traversal: %@", name)
            return
        }
        guard let urlString = data["url"] as? String,
              let baseURL = URL(string: urlString),
              baseURL.scheme == "https" else {
            NSLog("GMCP Media: play missing or invalid url")
            return
        }

        let volume = (data["volume"] as? NSNumber)?.floatValue ?? 100.0
        let priority = (data["priority"] as? NSNumber)?.intValue ?? 50
        let type = (data["type"] as? String) ?? "sound"
        let loops = (data["loops"] as? NSNumber)?.intValue ?? 0

        let currentPriority = type == "music" ? musicPriority : soundPriority
        if (type == "music" && musicPlayer?.isPlaying == true && priority < currentPriority) ||
           (type == "sound" && soundPlayer?.isPlaying == true && priority < currentPriority) {
            NSLog("GMCP Media: skipping %@ (priority %d < %d)", name, priority, currentPriority)
            return
        }

        let cachedFile = cachePath(baseURL: baseURL, name: name)
        let cachedDir = cachedFile.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: cachedDir, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: cachedFile.path) {
            NSLog("GMCP Media: playing cached %@", name)
            startPlayback(fileURL: cachedFile, type: type, volume: volume / 100.0,
                          loops: loops, priority: priority)
            return
        }

        let fileURL = baseURL.appendingPathComponent(name)

        NSLog("GMCP Media: downloading %@", fileURL.absoluteString)
        let task = session.downloadTask(with: fileURL) { [weak self] tempURL, response, error in
            guard let self else { return }
            if let error {
                NSLog("GMCP Media: download failed for %@: %@", name, error.localizedDescription)
                return
            }
            guard let tempURL else {
                NSLog("GMCP Media: no temp file for %@", name)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                NSLog("GMCP Media: HTTP %d for %@", httpResponse.statusCode, name)
                return
            }

            do {
                if FileManager.default.fileExists(atPath: cachedFile.path) {
                    try FileManager.default.removeItem(at: cachedFile)
                }
                try FileManager.default.moveItem(at: tempURL, to: cachedFile)
            } catch {
                NSLog("GMCP Media: cache failed for %@: %@", name, error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                NSLog("GMCP Media: playing downloaded %@", name)
                self.startPlayback(fileURL: cachedFile, type: type, volume: volume / 100.0,
                                   loops: loops, priority: priority)
            }
        }
        task.resume()
    }

    private func startPlayback(fileURL: URL, type: String, volume: Float,
                               loops: Int, priority: Int) {
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.volume = volume
            player.numberOfLoops = loops

            if type == "music" {
                musicPlayer?.stop()
                musicPlayer = player
                musicPriority = priority
            } else {
                soundPlayer?.stop()
                soundPlayer = player
                soundPriority = priority
            }

            NSLog("GMCP Media: starting %@ type=%@ volume=%.1f loops=%d priority=%d",
                  fileURL.lastPathComponent, type, volume, loops, priority)
            player.play()
        } catch {
            NSLog("GMCP Media: playback failed for %@: %@",
                  fileURL.lastPathComponent, error.localizedDescription)
        }
    }

    func stop(data: [String: Any]) {
        let type = data["type"] as? String
        if type == "music" || type == nil {
            NSLog("GMCP Media: stopping music")
            musicPlayer?.stop()
            musicPlayer = nil
            musicPriority = 0
        }
        if type == "sound" || type == nil {
            NSLog("GMCP Media: stopping sound")
            soundPlayer?.stop()
            soundPlayer = nil
            soundPriority = 0
        }
    }

    func stopAll() {
        stop(data: [:])
    }
}
