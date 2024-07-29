//
//  WindowManagerKey.swift
//  NotchNook
//
//  Created by Lori Montenegro on 28/07/24.
//

import SwiftUI

struct WindowManagerKey: EnvironmentKey {
    static let defaultValue: WindowsManager? = nil
}

extension EnvironmentValues {
    var windowManager: WindowsManager? {
        get { self[WindowManagerKey.self] }
        set { self[WindowManagerKey.self] = newValue }
    }
}
