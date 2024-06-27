//
//  RootView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI

struct RootView: View {
    var canBecomeKey: Binding<Bool>?
    var showSettings: (SettingsLib.PaneIdentifier?) -> ()
    var screenSize: CGSize
    var sparkleManager: SparkleManager
    var showChangelog: () -> ()
    var notchSize: CGSize
    var notchNook: NotchNook
    var captureFocusedWindow: () -> ()
    var refocusStoredWindow: () -> ()
    var makeKeyWindow: (() -> ())?
    @Environment(\.makeKeyWindow) private var defaultBecomeKeyWindow
    @Environment(\.canBecomeKey) private var defaultCanBecomeKey
    var body: some View {
        NotchView()
            .environment(\.openSettings, showSettings)
            .environment(\.screenSize, screenSize)
            .environment(\.sparkleManager, sparkleManager)
            .environment(\.showChangelog, showChangelog)
            .environment(\.notchSize, notchSize)
            .environment(\.notchNook, notchNook)
            .environment(\.captureFocusedWindow, captureFocusedWindow)
            .environment(\.refocusStoredWindow, refocusStoredWindow)
            .environment(\.makeKeyWindow, makeKeyWindow ?? defaultBecomeKeyWindow)
            .environment(\.canBecomeKey, canBecomeKey ?? defaultCanBecomeKey)
            .modelContainer(for: Note.self)
    }
}
