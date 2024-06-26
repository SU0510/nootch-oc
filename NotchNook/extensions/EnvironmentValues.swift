//
//  EnvironmentValues.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import SwiftDate

private struct OpenSettingsKey: EnvironmentKey {
    typealias Value = ((_ pane: SettingsLib.PaneIdentifier?) -> ())
    static let defaultValue: Self.Value = { _ in }
}

private struct ScreenIDKey: EnvironmentKey {
    typealias Value = UUID
    static let defaultValue = UUID()
}

private struct NamespaceKey: EnvironmentKey {
    static var defaultValue: Namespace.ID = Namespace().wrappedValue
}

private struct ScreenSizeKey: EnvironmentKey {
    static var defaultValue: CGSize = .zero
}

private struct TrialOverKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

private struct GetNowKey: EnvironmentKey {
    static var defaultValue: () -> Date = { Date() }
}

private struct SparkleManagerKey: EnvironmentKey {
    static var defaultValue = SparkleManager(updater: nil)
}

private struct ShowChangelogKey: EnvironmentKey {
    static var defaultValue: () -> () = { }
}

private struct CloseWindowKey: EnvironmentKey {
    static var defaultValue: () -> () = { }
}

private struct NotchSizeKey: EnvironmentKey {
    static var defaultValue: CGSize = .init(width: 184, height: 32)
}

private struct TrayKey: EnvironmentKey {
    static var defaultValue = Tray()
}

private struct NotchNookKey: EnvironmentKey {
    static var defaultValue = NotchNook()
}

extension EnvironmentValues {
    var notchNook: NotchNook {
        get { self[NotchNookKey.self] }
        set { self[NotchNookKey.self] = newValue }
    }
    var tray: Tray {
        get { self[TrayKey.self] }
        set { self[TrayKey.self] = newValue }
    }
    var notchSize: CGSize {
        get { self[NotchSizeKey.self] }
        set { self[NotchSizeKey.self] = newValue }
    }
    var closeWindow: () -> () {
        get { self[CloseWindowKey.self] }
        set { self[CloseWindowKey.self] = newValue }
    }
    var showChangelog: () -> () {
        get { self[ShowChangelogKey.self] }
        set { self[ShowChangelogKey.self] = newValue }
    }
    var sparkleManager: SparkleManager {
        get { self[SparkleManagerKey.self] }
        set { self[SparkleManagerKey.self] = newValue }
    }
    var getNow: () -> Date {
        get { self[GetNowKey.self] }
        set { self[GetNowKey.self] = newValue }
    }
    var trialOver: Bool {
        get { self[TrialOverKey.self] }
        set { self[TrialOverKey.self] = newValue }
    }
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
    var namespace: Namespace.ID {
        get { self[NamespaceKey.self] }
        set { self[NamespaceKey.self] = newValue }
    }
    var openSettings: ((_ pane: SettingsLib.PaneIdentifier?) -> ()) {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
    var screenID: UUID {
        get { self[ScreenIDKey.self] }
        set { self[ScreenIDKey.self] = newValue }
    }
}
