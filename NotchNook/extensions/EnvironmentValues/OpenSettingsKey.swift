//
//  OpenSettingsKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct OpenSettingsKey: EnvironmentKey {
    typealias Value = ((_ pane: SettingsLib.PaneIdentifier?) -> ())
    static let defaultValue: Self.Value = { _ in }
}

extension EnvironmentValues {
    var openSettings: ((_ pane: SettingsLib.PaneIdentifier?) -> ()) {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
}
