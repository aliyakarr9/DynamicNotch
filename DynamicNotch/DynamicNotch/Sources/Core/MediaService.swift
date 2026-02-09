import Foundation
import AppKit


struct MediaInfo: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artworkData: Data? = nil
    var artworkURL: String? = nil //
    var isPlaying: Bool = false
    var appName: String = "" //
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
        
        if isRunning("Spotify") {
            fetchSpotifyInfo()
        } else if isRunning("Music") {
            fetchMusicInfo()
        } else {
            
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

       
        let newInfo = MediaInfo(
            title: title,
            artist: artist,
            album: album,
            artworkData: nil,
            artworkURL: artworkUrlString,
            isPlaying: state == "playing",
            appName: "Spotify"
        )

        if newInfo != currentInfo {
            currentInfo = newInfo
            onMediaChange?(currentInfo)
        }
    }

 
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
      
        guard let descriptor = runAppleScript(script), descriptor.numberOfItems >= 4 else { return }

        let title = descriptor.atIndex(1)?.stringValue ?? ""
        let artist = descriptor.atIndex(2)?.stringValue ?? ""
        let album = descriptor.atIndex(3)?.stringValue ?? ""
        let state = descriptor.atIndex(4)?.stringValue ?? ""

        let newInfo = MediaInfo(
            title: title,
            artist: artist,
            album: album,
            artworkData: nil,
            artworkURL: nil,
            isPlaying: state == "playing",
            appName: "Music"
        )

        if newInfo != currentInfo {
            currentInfo = newInfo
            onMediaChange?(currentInfo)
        }
    }

    
    func playPause() {
        let app = currentInfo.appName
        guard !app.isEmpty else { return }
        _ = runAppleScript("tell application \"\(app)\" to playpause")
     
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
