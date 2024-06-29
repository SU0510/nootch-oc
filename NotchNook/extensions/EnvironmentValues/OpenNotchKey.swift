//
//  OpenNotchKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct OpenNotchKey: EnvironmentKey {
    static var defaultValue: (_ newMode: NotchNook.NotchMode) -> () = { _ in }
}

extension EnvironmentValues {
    var openNotch: (_ newMode: NotchNook.NotchMode) -> () {
        get { self[OpenNotchKey.self] }
        set { self[OpenNotchKey.self] = newValue }
    }
}
