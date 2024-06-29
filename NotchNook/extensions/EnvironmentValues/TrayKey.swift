//
//  TrayKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct TrayKey: EnvironmentKey {
    static var defaultValue = Tray()
}

extension EnvironmentValues {
    var tray: Tray {
        get { self[TrayKey.self] }
        set { self[TrayKey.self] = newValue }
    }
}
