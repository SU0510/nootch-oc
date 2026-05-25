//
//  MediaManager.swift
//  NotchNook
//
//  Created by Lori Montenegro on 25/06/25.
//

import SwiftUI
import Defaults
import MediaRemoteAdapter

// MARK: - MediaRemote multi-source typedefs (loaded lazily, macOS 15+)
private typealias MRGetNowPlayingClientsFunc = @convention(c) (DispatchQueue, @escaping ([AnyObject]?) -> Void) -> Void
private typealias MRClientGetBundleIDFunc    = @convention(c) (AnyObject?) -> CFString?
private typealias MRClientGetDisplayNameFunc = @convention(c) (AnyObject?) -> CFString?
private typealias MRClientGetPIDFunc         = @convention(c) (AnyObject?) -> Int32
private typealias MRSetElapsedTimeFunc       = @convention(c) (Double) -> Void

@Observable
class MediaManager {
    static let shared = MediaManager()

    // MARK: - Playback-position state (Feature 2)

    /// Seconds elapsed in the current track as reported by MediaRemote (updated ~4 Hz).
    var elapsedTime: Double = 0
    /// Total duration of the current track in seconds. `nil` = unknown (live stream / unsupported).
    var duration: Double? = nil

    // MARK: - Multi-source state (Feature 1)

    /// All NowPlaying clients currently registered with the system.
    var nowPlayingSources: [NowPlayingSource] = []
    /// Bundle ID the user explicitly pinned. When set, MediaManager prefers that source.
    var userPinnedClientID: String? = nil

    // MARK: - MediaRemote function pointers (loaded once)

    private var mrBundle: CFBundle?
    private var fnGetClients:    MRGetNowPlayingClientsFunc?
    private var fnClientBundleID: MRClientGetBundleIDFunc?
    private var fnClientName:    MRClientGetDisplayNameFunc?
    private var fnClientPID:     MRClientGetPIDFunc?
    private var fnSetElapsedTime: MRSetElapsedTimeFunc?
    private var mrFunctionsAvailable = false

    var isPlaying: Bool = false {
        willSet {
            let timerId = "pauseLiveActivityDismiss"
            let inactivityTimeout = Defaults[.liveActivitiesSettings].inactivityTimeoutInSecs
            if isPlaying != newValue {
                if newValue {
                    TimersManager.shared.removeTimer(timerId)
                } else {
                    TimersManager.shared.addTimer(timerId, delay: inactivityTimeout) { _ in
                        ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
                    }
                }
            }
        }
    }
    
    var track: Track = .empty
    var preferredMediaSource: MediaSource = Defaults[.generalSettings].preferredMediaSource
    
    private var mediaController: MediaController
    private var appRunningCheckTimer: Timer?
    
    private var lastTrackUpdate: TimeInterval = 0
    private var lastAppCheck: TimeInterval = 0
    private var scriptCooldowns: [String: TimeInterval] = [:]
    private var throttledTrackUpdate: (() -> Void)?
    private var lastReceivedTrackInfo: TrackInfo?
    
    private let trackUpdateInterval: TimeInterval = 1.0
    private let appCheckInterval: TimeInterval = 10.0
    private let scriptCooldownInterval: TimeInterval = 2.0
    
    // MARK: Lifecycle
    
    private init() {
        mediaController = MediaController()
        loadMediaRemoteFunctions()
        setupMediaControllerListeners()
        reconfigureMediaController()
    }

    // MARK: - MediaRemote private-framework loader

    private func loadMediaRemoteFunctions() {
        guard let b = CFBundleCreate(kCFAllocatorDefault,
                NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
            print("[MediaManager] MediaRemote.framework unavailable — multi-source and seek disabled.")
            return
        }
        mrBundle = b

        func load<T>(_ name: String) -> T? {
            guard let ptr = CFBundleGetFunctionPointerForName(b, name as CFString) else { return nil }
            return unsafeBitCast(ptr, to: T.self)
        }

        fnGetClients     = load("MRMediaRemoteGetNowPlayingClients")
        fnClientBundleID = load("MRNowPlayingClientGetBundleIdentifier")
        fnClientName     = load("MRNowPlayingClientGetDisplayName")
        fnClientPID      = load("MRNowPlayingClientGetProcessIdentifier")
        fnSetElapsedTime = load("MRMediaRemoteSetElapsedTime")

        mrFunctionsAvailable = fnGetClients != nil
        if !mrFunctionsAvailable {
            print("[MediaManager] MRMediaRemoteGetNowPlayingClients not found — multi-source disabled.")
        }
        if fnSetElapsedTime == nil {
            print("[MediaManager] MRMediaRemoteSetElapsedTime not found — seek disabled.")
        }
    }
    
    deinit {
        mediaController.stopListening()
    }
    
    // MARK: Listeners and timers
    
    private func setupMediaControllerListeners() {
        throttledTrackUpdate = throttleWithTrailing(interval: 1.0) { [weak self] in
            guard let self = self else { return }
            if let trackInfo = self.lastReceivedTrackInfo {
                self.handleTrackInfoUpdate(trackInfo)
            }
        }
        
        mediaController.onTrackInfoReceived = { [weak self] trackInfo in
            self?.lastReceivedTrackInfo = trackInfo
            self?.throttledTrackUpdate?()
            // Capture duration alongside track updates (no throttle needed — cheap).
            DispatchQueue.main.async {
                if let micros = trackInfo.payload.durationMicros, micros > 0 {
                    self?.duration = micros / 1_000_000
                } else {
                    self?.duration = nil
                }
            }
            // Refresh the client list whenever now-playing changes.
            self?.refreshNowPlayingClients()
        }

        mediaController.onPlaybackTimeUpdate = { [weak self] seconds in
            DispatchQueue.main.async {
                self?.elapsedTime = seconds
            }
        }
        
        mediaController.onListenerTerminated = { [weak self] in
            self?.resetData()
            self?.stopListeningAndKillProcesses()
        }
    }

    // MARK: - Multi-source client discovery

    func refreshNowPlayingClients() {
        guard mrFunctionsAvailable,
              let getClients   = fnGetClients,
              let getBundleID  = fnClientBundleID,
              let getName      = fnClientName,
              let getPID       = fnClientPID else { return }

        getClients(.main) { [weak self] clientRefs in
            guard let self = self else { return }
            guard let refs = clientRefs, !refs.isEmpty else {
                DispatchQueue.main.async { self.nowPlayingSources = [] }
                return
            }

            var sources: [NowPlayingSource] = []
            for ref in refs {
                let bundleID = (getBundleID(ref) as String?) ?? ""
                guard !bundleID.isEmpty else { continue }
                let displayName = (getName(ref) as String?) ?? bundleID
                let pid         = getPID(ref)
                sources.append(NowPlayingSource(bundleIdentifier: bundleID, displayName: displayName, pid: pid))
            }

            DispatchQueue.main.async {
                self.nowPlayingSources = sources
                // If the pinned client is no longer present, unpin.
                if let pinned = self.userPinnedClientID,
                   !sources.contains(where: { $0.bundleIdentifier == pinned }) {
                    self.userPinnedClientID = nil
                }
            }
        }
    }

    /// Returns the source that should be considered active. Pinned wins; otherwise the
    /// source matching the current track's bundle ID.
    var activeSource: NowPlayingSource? {
        if let pinned = userPinnedClientID {
            return nowPlayingSources.first(where: { $0.bundleIdentifier == pinned })
        }
        return nowPlayingSources.first(where: { $0.bundleIdentifier == track.appBundleId })
            ?? nowPlayingSources.first
    }
    
    func throttleWithTrailing(interval: TimeInterval, queue: DispatchQueue = .main, action: @escaping () -> Void) -> () -> Void {
        var lastExecutionTime: TimeInterval = 0
        var workItem: DispatchWorkItem?
        
        return {
            let now = Date().timeIntervalSince1970
            let timeSinceLast = now - lastExecutionTime
            
            workItem?.cancel()
            
            if timeSinceLast >= interval {
                lastExecutionTime = now
                action()
            } else {
                let delay = interval - timeSinceLast
                workItem = DispatchWorkItem {
                    lastExecutionTime = Date().timeIntervalSince1970
                    action()
                }
                queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
            }
        }
    }
    
    /// Workaround for when not detecting app closure
    private func startAppRunningMonitor() {
        appRunningCheckTimer?.invalidate()
        appRunningCheckTimer = Timer.scheduledTimer(withTimeInterval: appCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date().timeIntervalSince1970
            guard now - self.lastAppCheck >= self.appCheckInterval else { return }
            self.lastAppCheck = now
            
            if self.resetIfNeeded() {
                self.appRunningCheckTimer?.invalidate()
                self.appRunningCheckTimer = nil
                self.stopListeningAndKillProcesses()
            }
        }
    }
    
    // MARK: Update methods
    
    private func handleTrackInfoUpdate(_ trackInfo: TrackInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let track = trackInfo.payload
            
            if let isPlaying = track.isPlaying {
                updateTrackInfo(title: track.title, artist: track.artist, album: track.album, isPlaying: isPlaying, albumArtImage: track.artwork, appName: track.applicationName, bundleIdentifier: track.bundleIdentifier)
            } else {
                resetData()
            }
        }
    }
    
    private func updateTrackInfo(title: String?, artist: String?, album: String?, isPlaying: Bool, albumArtImage: NSImage?, appName: String?, bundleIdentifier: String?) {
        var newTrack = Track()
        newTrack.title = title ?? ""
        newTrack.artist = artist ?? ""
        newTrack.album = album ?? ""
        newTrack.albumArt = albumArtImage ?? NSImage()
        newTrack.appName = appName ?? ""
        newTrack.appBundleId = bundleIdentifier ?? ""
        newTrack.browserBundleId = BrowserType.getBrowserBundleId(for: appName ?? "")
        
        let playingStateChanged = self.isPlaying != isPlaying
        let trackChanged = self.track.isValidReplacement(newTrack)
        
        guard playingStateChanged || trackChanged else { return }
        
        // Update UI only if necessary
        DispatchQueue.main.async {
            if trackChanged {
                self.track = newTrack
                self.startAppRunningMonitor()
            }
            if playingStateChanged {
                self.isPlaying = isPlaying
            }
            if trackChanged || playingStateChanged {
                self.updateLiveActivities()
            }
        }
    }
    
    private func updateLiveActivities() {
        if track != .empty {
            if !isPlaying { return }
            ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.media)
        } else {
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
        }
    }
    
    // MARK: Private helpers
    
    private func runAppleScript(script: String) {
        // Caching mechanism for script executions: prevents duplicate/rapid script executions
        let now = Date().timeIntervalSince1970
        if let lastExec = scriptCooldowns[script], now - lastExec < scriptCooldownInterval {
            return
        }
        scriptCooldowns[script] = now
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Error running AppleScript: \(error)")
        }
    }
    
    private func resetIfNeeded() -> Bool {
        let appName = track.appName
        if appName.isEmpty { return true }
        
        let isRunning = isAppRunning(appName)
        if !isRunning {
            resetData()
            return true
        }
        
        return false
    }
    
    private func isAppRunning(_ appName: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.localizedName?.contains(appName) == true
        }
    }
    
    // MARK: Public methods
    
    func isLikelyBrowserApp() -> Bool {
        preferredMediaSource == .systemWide && track.browserBundleId != nil
    }
    
    func reconfigureMediaController() {
        resetData()
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            self.mediaController.stopListening()
            killLibProcesses()
                        
            // Update status on main thread
            DispatchQueue.main.async {
                self.mediaController = MediaController(bundleIdentifier: self.preferredMediaSource == .systemWide ? nil : self.preferredMediaSource.bundleIdentifier)
                self.setupMediaControllerListeners()
                self.mediaController.startListening()
                
                guard self.track == .empty else {
                    self.updateLiveActivities()
                    return
                }
                if self.preferredMediaSource != .systemWide {
                    if self.isAppRunning(self.preferredMediaSource.name) {
                        self.forceMediaControllerRestart()
                    }
                }
            }
        }
    }

    
    func forceMediaControllerRestart(appName: String? = nil) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            mediaController.stopListening()
            killLibProcesses()

            let appName = appName != nil ? "\"\(appName!)\"" : preferredMediaSource.name
            runAppleScript(script: "tell application \(appName) to playpause")
            
            mediaController = MediaController(bundleIdentifier: preferredMediaSource.bundleIdentifier)
            setupMediaControllerListeners()
            mediaController.startListening()
            
            runAppleScript(script: "tell application \(appName) to playpause")
            
            DispatchQueue.main.async {
                self.updateLiveActivities()
            }
        }
    }
    
    func stopListeningAndKillProcesses() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            mediaController.stopListening()
            killLibProcesses()
        }
    }
    
    /// Workaround for CPU usage bug inside lib
    func killLibProcesses() {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "pkill -f MediaRemoteAdapter; pkill -f 'MediaRemoteAdapter.*perl'"]
        try? task.run()
        task.waitUntilExit()
    }
    
    // MARK: User actions
    
    func resetData() {
        DispatchQueue.main.async {
            self.track = .empty
            self.isPlaying = false
            self.elapsedTime = 0
            self.duration = nil
            self.nowPlayingSources = []
            self.userPinnedClientID = nil
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
            self.mediaController.stopListening()
        }
    }
    
    func togglePlayPause() {
        switch preferredMediaSource {
            case .systemWide:
                mediaController.togglePlayPause()
            case .appleMusic, .spotify:
                runAppleScript(script: "tell application \(preferredMediaSource.name) to playpause")
        }
    }
    
    func goToPreviousTrack() {
        switch preferredMediaSource {
            case .systemWide:
                mediaController.previousTrack()
            case .appleMusic, .spotify:
                runAppleScript(script: "tell application \(preferredMediaSource.name) to previous track")
        }
    }
    
    func goToNextTrack() {
        switch preferredMediaSource {
            case .systemWide:
                mediaController.nextTrack()
            case .appleMusic, .spotify:
                runAppleScript(script: "tell application \(preferredMediaSource.name) to next track")
        }
    }
    
    func openApp() {
        guard let browserBundleId = track.browserBundleId else {
            SystemAppMeta(bundleId: track.appBundleId).openApp()
            return
        }
        SystemAppMeta(bundleId: browserBundleId).openApp()
    }

    // MARK: - Seek

    /// Seek to `seconds` in the current track. Falls back silently if `setTime` or
    /// `MRMediaRemoteSetElapsedTime` are not available.
    func seek(to seconds: Double) {
        // MediaController.setTime() calls the Perl backend which uses the MR set_time command.
        mediaController.setTime(seconds: seconds)
        // Also drive via the direct MR function pointer if available (belt+suspenders).
        fnSetElapsedTime?(seconds)
    }

    // MARK: - Source pinning

    func pinSource(_ source: NowPlayingSource) {
        userPinnedClientID = source.bundleIdentifier
    }

    func unpinSource() {
        userPinnedClientID = nil
    }
}
