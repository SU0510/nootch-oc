//
//  CheckForUpdatesViewModel.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Sparkle

final class CheckForUpdatesViewModel: ObservableObject {
    private weak var updater: SPUUpdater?
    @Published var canCheckForUpdates = false
    @Published var _automaticallyChecksForUpdates = false
    var automaticallyChecksForUpdates: Bool {
        get { _automaticallyChecksForUpdates }
        set { updater?.automaticallyChecksForUpdates = newValue }
    }
    @Published var _automaticallyDownloadsUpdates = false
    var automaticallyDownloadsUpdates: Bool {
        get { _automaticallyDownloadsUpdates }
        set { updater?.automaticallyDownloadsUpdates = newValue }
    }

    init(updater: SPUUpdater) {
        self.updater = updater
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .assign(to: &$_automaticallyChecksForUpdates)
        updater.publisher(for: \.automaticallyDownloadsUpdates)
            .assign(to: &$_automaticallyDownloadsUpdates)
    }
}
