//
//  CloseNotchKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct CloseNotchKey: EnvironmentKey {
    static var defaultValue: (_ doVibrate: Bool, _ unhover: Bool) -> () = { _, _ in }
}

extension EnvironmentValues {
    var closeNotch: (_ doVibrate: Bool, _ unhover: Bool) -> () {
        get { self[CloseNotchKey.self] }
        set { self[CloseNotchKey.self] = newValue }
    }
}
