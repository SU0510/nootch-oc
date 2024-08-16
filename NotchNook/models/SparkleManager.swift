//
//  SparkleManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//
#if !SETAPP_BUILD
import SwiftUI
import Sparkle
import Combine

@Observable
class SparkleManager {
    var updaterController: SPUStandardUpdaterController?
    weak var updater: SPUUpdater? { updaterController?.updater }
    
    var cancellables = [AnyCancellable?]()
    
    var _automaticallyChecksForUpdates: Bool = false
    var automaticallyChecksForUpdates: Bool {
            get { _automaticallyChecksForUpdates }
            set { _automaticallyChecksForUpdates = newValue }
        }
    var _automaticallyDownloadsUpdates: Bool = false
    var automaticallyDownloadsUpdates: Bool {
            get { _automaticallyDownloadsUpdates }
            set { _automaticallyDownloadsUpdates = newValue }
        }
    var _canCheckForUpdates: Bool  = false
    var canCheckForUpdates: Bool {
            get { _canCheckForUpdates }
            set { _canCheckForUpdates = newValue }
        }
    var feedURL: URL? = nil
    var hostBundle: Bundle = .main
    var _httpHeaders: [String : String]? = nil
    var httpHeaders: [String : String]? {
            get { _httpHeaders }
            set { _httpHeaders = newValue }
        }
    var _lastUpdateCheckDate: Date? = nil
    var lastUpdateCheckDate: Date? {
            get { _lastUpdateCheckDate }
            set { _lastUpdateCheckDate = newValue }
        }
    var _sendsSystemProfile: Bool = false
    var sendsSystemProfile: Bool {
            get { _sendsSystemProfile }
            set { _sendsSystemProfile = newValue }
        }
    var _sessionInProgress: Bool = false
    var sessionInProgress: Bool {
            get { _sessionInProgress }
            set { _sessionInProgress = newValue }
        }
    var _systemProfileArray = [[String : String]]()
    var systemProfileArray: [[String : String]] {
            get { _systemProfileArray }
            set { _systemProfileArray = newValue }
        }
    var _updateCheckInterval: TimeInterval = 86400
    var updateCheckInterval: TimeInterval {
            get { _updateCheckInterval }
            set { _updateCheckInterval = newValue }
        }
    var _userAgentString: String = ""
    var userAgentString: String {
            get { _userAgentString }
            set { _userAgentString = newValue }
        }
    
    init(updaterController: SPUStandardUpdaterController?) {
        self.updaterController = updaterController
        guard let updater = self.updater else { return }
        setupInitialVars(updater: updater)
        setupUpdateListeners(updater: updater)
    }
    
    deinit {
        self.cancellables.forEach { $0?.cancel() }
    }
    
    func setupInitialVars(updater: SPUUpdater) {
        _automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        _automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
        _canCheckForUpdates = updater.canCheckForUpdates
        _feedURL = updater.feedURL
        _hostBundle = updater.hostBundle
        _httpHeaders = updater.httpHeaders
        _lastUpdateCheckDate = updater.lastUpdateCheckDate
        _sendsSystemProfile = updater.sendsSystemProfile
        _sessionInProgress = updater.sessionInProgress
        _systemProfileArray = updater.systemProfileArray
        _updateCheckInterval = updater.updateCheckInterval
        _userAgentString = updater.userAgentString
    }
    
    func setupUpdateListeners(updater: SPUUpdater) {
        self.cancellables.append(updater.publisher(for: \.automaticallyChecksForUpdates).sink { self._automaticallyChecksForUpdates = $0 })
        self.cancellables.append(updater.publisher(for: \.automaticallyDownloadsUpdates).sink { self._automaticallyDownloadsUpdates = $0 })
        self.cancellables.append(updater.publisher(for: \.canCheckForUpdates).sink { self._canCheckForUpdates = $0 })
        self.cancellables.append(updater.publisher(for: \.feedURL).sink { self._feedURL = $0 })
        self.cancellables.append(updater.publisher(for: \.hostBundle).sink { self._hostBundle = $0 })
        self.cancellables.append(updater.publisher(for: \.httpHeaders).sink { self._httpHeaders = $0 })
        self.cancellables.append(updater.publisher(for: \.lastUpdateCheckDate).sink { self._lastUpdateCheckDate = $0 })
        self.cancellables.append(updater.publisher(for: \.sendsSystemProfile).sink { self._sendsSystemProfile = $0 })
        self.cancellables.append(updater.publisher(for: \.sessionInProgress).sink { self._sessionInProgress = $0 })
        self.cancellables.append(updater.publisher(for: \.systemProfileArray).sink { self._systemProfileArray = $0 })
        self.cancellables.append(updater.publisher(for: \.updateCheckInterval).sink { self._updateCheckInterval = $0 })
        self.cancellables.append(updater.publisher(for: \.userAgentString).sink { self._userAgentString = $0 })
    }
    
    func checkForUpdateInformation() { updater?.checkForUpdateInformation() }
    func checkForUpdates() { updater?.checkForUpdates() }
    func checkForUpdatesInBackground() { updater?.checkForUpdatesInBackground() }
    func clearFeedURLFromUserDefaults() { updater?.clearFeedURLFromUserDefaults() }
    func resetUpdateCycle() { updater?.resetUpdateCycle() }
    func resetUpdateCycleAfterShortDelay() { updater?.resetUpdateCycleAfterShortDelay() }
    func start() throws { try updater?.start() }
}
#endif
