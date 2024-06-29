//
//  FocusFrontmostWindowKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct FocusFrontmostWindowKey: EnvironmentKey {
    static var defaultValue: () -> () = {}
}

extension EnvironmentValues {
    var focusFrontmostWindow: () -> () {
        get { self[FocusFrontmostWindowKey.self] }
        set { self[FocusFrontmostWindowKey.self] = newValue }
    }
}
