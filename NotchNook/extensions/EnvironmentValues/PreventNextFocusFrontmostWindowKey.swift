//
//  PreventNextFocusFrontmostWindowKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct PreventNextFocusFrontmostWindowKey: EnvironmentKey {
    static var defaultValue: () -> () = {}
}

extension EnvironmentValues {
    var preventNextFocusFrontmostWindow: () -> () {
        get { self[PreventNextFocusFrontmostWindowKey.self] }
        set { self[PreventNextFocusFrontmostWindowKey.self] = newValue }
    }
}
