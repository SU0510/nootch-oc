//
//  OpenNotchKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct OpenNotchKey: EnvironmentKey {
    static var defaultValue: (_ newMode: NotchNookState.NotchMode) -> () = { _ in }
}

extension EnvironmentValues {
    var openNotch: (_ newMode: NotchNookState.NotchMode) -> () {
        get { self[OpenNotchKey.self] }
        set { self[OpenNotchKey.self] = newValue }
    }
}
