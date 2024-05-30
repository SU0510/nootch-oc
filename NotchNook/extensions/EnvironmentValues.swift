//
//  EnvironmentValues.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI

private struct NotchHeightKey: EnvironmentKey {
    typealias Value = CGFloat
    static let defaultValue = GeneralSettings().handleSize.height
}

private struct OpenSettingsKey: EnvironmentKey {
    typealias Value = ((_ pane: SettingsPane.PaneIdentifier?) -> ())
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

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
    var namespace: Namespace.ID {
        get { self[NamespaceKey.self] }
        set { self[NamespaceKey.self] = newValue }
    }
    var notchHeight: CGFloat {
        get { self[NotchHeightKey.self] }
        set { self[NotchHeightKey.self] = newValue }
    }
    var openSettings: ((_ pane: SettingsPane.PaneIdentifier?) -> ()) {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
    var screenID: UUID {
        get { self[ScreenIDKey.self] }
        set { self[ScreenIDKey.self] = newValue }
    }
}
