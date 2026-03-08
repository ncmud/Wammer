import AVFoundation
import Foundation
import MediaPlayer

extension Notification.Name {
    static let gmcpMusicStateChanged = Notification.Name("GMCPMusicStateChanged")
}

final class GMCPMediaManager: NSObject, AVAudioPlayerDelegate {
    private var musicPlayer: AVAudioPlayer?
    private var soundPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?
    private var musicPriority: Int = 0
    private var soundPriority: Int = 0
    private var ambientPausedByServer: Bool = false
    private var musicPausedByUser: Bool = false
    private let cacheDirectory: URL
    private let session: URLSession
    /// The hostname of the MUD server this manager is connected to.
    var serverHostname: String?
    /// When true, GMCP server music is ignored and ambient keeps playing.
    var overrideGameMusic: Bool = false
    /// Display name for the current world (used in Now Playing as "artist").
    var worldName: String?

    private var currentAmbientTrackName: String?
    private var currentServerMusicName: String?

    override init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("GMCPMedia", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)

        super.init()
        configureRemoteCommands()
    }

    private func activateAudioSession() {
        #if !targetEnvironment(macCatalyst)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            NSLog("GMCP Media: failed to configure audio session: %@", error.localizedDescription)
        }
        #endif
    }

    private func deactivateAudioSessionIfIdle() {
        #if !targetEnvironment(macCatalyst)
        guard ambientPlayer == nil, musicPlayer?.isPlaying != true, soundPlayer?.isPlaying != true else {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("GMCP Media: failed to deactivate audio session: %@", error.localizedDescription)
        }
        #endif
    }

    // MARK: - Remote Commands (Lock Screen / AirPods / CarPlay)

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resumeMusic()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pauseMusic()
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isMusicPlaying {
                self.pauseMusic()
            } else {
                self.resumeMusic()
            }
            return .success
        }
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stopMusic()
            return .success
        }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [:]

        // Prefer server music for Now Playing when it's active; fall back to ambient.
        if let player = musicPlayer, let trackName = currentServerMusicName {
            info[MPMediaItemPropertyTitle] = (trackName as NSString).lastPathComponent
            info[MPMediaItemPropertyArtist] = worldName ?? serverHostname ?? "MUD"
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            info[MPMediaItemPropertyPlaybackDuration] = player.duration
            info[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        } else if let player = ambientPlayer, let trackName = currentAmbientTrackName {
            info[MPMediaItemPropertyTitle] = (trackName as NSString).lastPathComponent
            info[MPMediaItemPropertyArtist] = worldName ?? serverHostname ?? "MUD"
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            info[MPMediaItemPropertyPlaybackDuration] = player.duration
            info[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info.isEmpty ? nil : info
        NotificationCenter.default.post(name: .gmcpMusicStateChanged, object: nil)
    }

    // MARK: - Ambient Music

    /// Start playing ambient music from a relative path in the music library.
    func startAmbient(relativePath: String) {
        let fileURL = cacheDirectory.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            NSLog("GMCP Media: ambient file not found: %@", relativePath)
            return
        }

        activateAudioSession()
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.numberOfLoops = -1  // infinite loop
            player.volume = 1.0
            player.delegate = self

            ambientPlayer?.stop()
            ambientPlayer = player
            ambientPausedByServer = false
            currentAmbientTrackName = relativePath

            player.play()
            NSLog("GMCP Media: ambient started: %@", relativePath)
            updateNowPlaying()
        } catch {
            NSLog("GMCP Media: ambient playback failed: %@", error.localizedDescription)
        }
    }

    func pauseAmbient() {
        ambientPlayer?.pause()
        updateNowPlaying()
    }

    func resumeAmbient() {
        ambientPlayer?.play()
        ambientPausedByServer = false
        updateNowPlaying()
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        ambientPausedByServer = false
        currentAmbientTrackName = nil
        updateNowPlaying()
        deactivateAudioSessionIfIdle()
    }

    // MARK: - Unified Music Controls

    /// Pause whichever music channel is active (ambient or server).
    func pauseMusic() {
        if ambientPlayer?.isPlaying == true {
            ambientPlayer?.pause()
        }
        if musicPlayer?.isPlaying == true {
            musicPlayer?.pause()
            musicPausedByUser = true
        }
        updateNowPlaying()
    }

    /// Resume whichever music channel was paused.
    func resumeMusic() {
        if ambientPlayer != nil && ambientPlayer?.isPlaying == false {
            ambientPlayer?.play()
            ambientPausedByServer = false
        }
        if musicPausedByUser {
            musicPlayer?.play()
            musicPausedByUser = false
        }
        updateNowPlaying()
    }

    /// Stop all music (ambient and server). Sounds are unaffected.
    func stopMusic() {
        stopAmbient()
        musicPlayer?.stop()
        musicPlayer = nil
        musicPriority = 0
        musicPausedByUser = false
        currentServerMusicName = nil
        updateNowPlaying()
        deactivateAudioSessionIfIdle()
    }

    /// Whether any music (ambient or server) is currently playing.
    var isMusicPlaying: Bool {
        ambientPlayer?.isPlaying == true || musicPlayer?.isPlaying == true
    }

    /// Whether any music (ambient or server) exists but is paused.
    var isMusicPaused: Bool {
        let ambientPaused = ambientPlayer != nil && ambientPlayer?.isPlaying == false
        let serverPaused = musicPlayer != nil && musicPausedByUser
        return ambientPaused || serverPaused
    }

    /// Whether ambient music is actively playing right now.
    var isAmbientPlaying: Bool {
        ambientPlayer?.isPlaying == true
    }

    /// Whether ambient music exists but is paused (by user or server).
    var isAmbientPaused: Bool {
        ambientPlayer != nil && ambientPlayer?.isPlaying == false
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === musicPlayer {
            // Server music finished — resume ambient if it was paused
            musicPlayer = nil
            musicPriority = 0
            musicPausedByUser = false
            currentServerMusicName = nil
            if ambientPausedByServer {
                resumeAmbient()
            } else {
                deactivateAudioSessionIfIdle()
            }
            updateNowPlaying()
        }
    }

    // MARK: - GMCP Server Media

    /// Build the cache path for a sound file, namespaced by server URL.
    /// e.g. `GMCPMedia/ncmud.net/sounds/NC/backstab.wav`
    /// This mirrors the URL structure so you can reconstruct the full URL from the path.
    func cachePath(baseURL: URL, name: String) -> URL {
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

        // If override is on, ignore all server music (but not sounds)
        if type == "music" && overrideGameMusic {
            NSLog("GMCP Media: ignoring server music (override enabled)")
            return
        }

        let currentPriority = type == "music" ? musicPriority : soundPriority
        if (type == "music" && musicPlayer?.isPlaying == true && priority < currentPriority) ||
           (type == "sound" && soundPlayer?.isPlaying == true && priority < currentPriority) {
            NSLog("GMCP Media: skipping %@ (priority %d < %d)", name, priority, currentPriority)
            return
        }

        let cachedFile = cachePath(baseURL: baseURL, name: name)
        let cachedDir = cachedFile.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: cachedDir, withIntermediateDirectories: true)

        let normalizedVolume = volume / 100.0
        let hostname = serverHostname ?? baseURL.host ?? "unknown"
        if FileManager.default.fileExists(atPath: cachedFile.path) {
            NSLog("GMCP Media: playing cached %@", name)
            MusicLibrary.shared.addTrack(hostname: hostname, name: name, type: type, baseURL: baseURL)
            startPlayback(fileURL: cachedFile, type: type, volume: normalizedVolume,
                          loops: loops, priority: priority)
        } else {
            let fileURL = baseURL.appendingPathComponent(name)
            NSLog("GMCP Media: downloading %@", fileURL.absoluteString)
            downloadAndPlay(fileURL: fileURL, cachedFile: cachedFile) {
                MusicLibrary.shared.addTrack(hostname: hostname, name: name, type: type, baseURL: baseURL)
                self.startPlayback(fileURL: cachedFile, type: type, volume: normalizedVolume,
                                   loops: loops, priority: priority)
            }
        }
    }

    private func downloadAndPlay(fileURL: URL, cachedFile: URL, completion: @escaping () -> Void) {
        let task = session.downloadTask(with: fileURL) { tempURL, response, error in
            if let error {
                NSLog("GMCP Media: download failed: %@", error.localizedDescription)
                return
            }
            guard let tempURL else {
                NSLog("GMCP Media: no temp file for %@", fileURL.lastPathComponent)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                NSLog("GMCP Media: HTTP %d for %@", httpResponse.statusCode, fileURL.lastPathComponent)
                return
            }

            do {
                if FileManager.default.fileExists(atPath: cachedFile.path) {
                    try FileManager.default.removeItem(at: cachedFile)
                }
                try FileManager.default.moveItem(at: tempURL, to: cachedFile)
            } catch {
                NSLog("GMCP Media: cache failed: %@", error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                NSLog("GMCP Media: playing downloaded %@", fileURL.lastPathComponent)
                completion()
            }
        }
        task.resume()
    }

    private func startPlayback(fileURL: URL, type: String, volume: Float,
                               loops: Int, priority: Int) {
        activateAudioSession()
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.volume = volume
            player.numberOfLoops = loops

            if type == "music" {
                // Pause ambient while server music plays
                if ambientPlayer?.isPlaying == true {
                    ambientPlayer?.pause()
                    ambientPausedByServer = true
                }
                musicPlayer?.stop()
                musicPlayer = player
                musicPriority = priority
                musicPausedByUser = false
                currentServerMusicName = fileURL.lastPathComponent
                player.delegate = self
            } else {
                soundPlayer?.stop()
                soundPlayer = player
                soundPriority = priority
            }

            NSLog("GMCP Media: starting %@ type=%@ volume=%.1f loops=%d priority=%d",
                  fileURL.lastPathComponent, type, volume, loops, priority)
            player.play()
            if type == "music" { updateNowPlaying() }
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
            musicPausedByUser = false
            currentServerMusicName = nil
            // Resume ambient if it was paused by server music
            if ambientPausedByServer {
                resumeAmbient()
            }
            updateNowPlaying()
        }
        if type == "sound" || type == nil {
            NSLog("GMCP Media: stopping sound")
            soundPlayer?.stop()
            soundPlayer = nil
            soundPriority = 0
        }
        deactivateAudioSessionIfIdle()
    }

    func stopAll() {
        stop(data: [:])
        stopAmbient()
    }
}
