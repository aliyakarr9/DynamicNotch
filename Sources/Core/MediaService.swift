import Foundation
import AppKit

struct MediaInfo: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artworkData: Data? = nil
    var isPlaying: Bool = false
    var appName: String = "" // "Spotify" or "Music"
}

class MediaService {
    var onMediaChange: ((MediaInfo) -> Void)?
    private var timer: Timer?
    private var currentInfo: MediaInfo = MediaInfo()

    init() {
        startPolling()
    }

    deinit {
        stopPolling()
    }

    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchMediaInfo()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchMediaInfo() {
        // Prioritize Spotify, then Music
        if isRunning("Spotify") {
            fetchSpotifyInfo()
        } else if isRunning("Music") {
            fetchMusicInfo()
        } else {
            // No supported player running
            let emptyInfo = MediaInfo()
            if currentInfo != emptyInfo {
                currentInfo = emptyInfo
                onMediaChange?(currentInfo)
            }
        }
    }

    private func isRunning(_ appName: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.localizedName == appName }
    }

    private func runAppleScript(_ script: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            return scriptObject.executeAndReturnError(&error)
        }
        return nil
    }

    // MARK: - Spotify
    private func fetchSpotifyInfo() {
        let script = """
        tell application "Spotify"
            set currentTrack to name of current track
            set currentArtist to artist of current track
            set currentAlbum to album of current track
            set playerState to player state as string
            set artworkUrl to artwork url of current track
            return {currentTrack, currentArtist, currentAlbum, playerState, artworkUrl}
        end tell
        """

        guard let descriptor = runAppleScript(script), descriptor.numberOfItems >= 4 else { return }

        let title = descriptor.atIndex(1)?.stringValue ?? ""
        let artist = descriptor.atIndex(2)?.stringValue ?? ""
        let album = descriptor.atIndex(3)?.stringValue ?? ""
        let state = descriptor.atIndex(4)?.stringValue ?? ""
        let artworkUrlString = descriptor.atIndex(5)?.stringValue ?? ""

        var newInfo = MediaInfo(
            title: title,
            artist: artist,
            album: album,
            artworkData: currentInfo.artworkData, // Keep existing unless changed
            isPlaying: state == "playing",
            appName: "Spotify"
        )

        // Fetch artwork if URL changed
        // Note: In a real app, we'd cache this more robustly. For simplicity, we just fetch if title changed.
        if newInfo.title != currentInfo.title {
            if let url = URL(string: artworkUrlString), let data = try? Data(contentsOf: url) {
                newInfo.artworkData = data
            } else {
                newInfo.artworkData = nil
            }
        }

        if newInfo != currentInfo {
            currentInfo = newInfo
            onMediaChange?(currentInfo)
        }
    }

    // MARK: - Apple Music
    private func fetchMusicInfo() {
        let script = """
        tell application "Music"
            set currentTrack to name of current track
            set currentArtist to artist of current track
            set currentAlbum to album of current track
            set playerState to player state as string
            return {currentTrack, currentArtist, currentAlbum, playerState}
        end tell
        """
        // Note: Apple Music artwork extraction via AppleScript is slow/complex (needs raw data export).
        // For Phase 2 prototype, we might skip artwork or use a simpler placeholder if too slow.

        guard let descriptor = runAppleScript(script), descriptor.numberOfItems >= 4 else { return }

        let title = descriptor.atIndex(1)?.stringValue ?? ""
        let artist = descriptor.atIndex(2)?.stringValue ?? ""
        let album = descriptor.atIndex(3)?.stringValue ?? ""
        let state = descriptor.atIndex(4)?.stringValue ?? ""

        let newInfo = MediaInfo(
            title: title,
            artist: artist,
            album: album,
            artworkData: nil, // Complex to get via AppleScript efficiently
            isPlaying: state == "playing",
            appName: "Music"
        )

        if newInfo != currentInfo {
            currentInfo = newInfo
            onMediaChange?(currentInfo)
        }
    }

    // MARK: - Controls
    func playPause() {
        let app = currentInfo.appName
        guard !app.isEmpty else { return }
        _ = runAppleScript("tell application \"\(app)\" to playpause")
        // Optimistic update
        currentInfo.isPlaying.toggle()
        onMediaChange?(currentInfo)
    }

    func nextTrack() {
        let app = currentInfo.appName
        guard !app.isEmpty else { return }
        _ = runAppleScript("tell application \"\(app)\" to next track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.fetchMediaInfo() }
    }

    func previousTrack() {
        let app = currentInfo.appName
        guard !app.isEmpty else { return }
        _ = runAppleScript("tell application \"\(app)\" to previous track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.fetchMediaInfo() }
    }
}
