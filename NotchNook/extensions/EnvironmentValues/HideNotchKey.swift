//
//  HideNotchKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct HideNotchKey: EnvironmentKey {
    static var defaultValue: () -> () = {}
}

extension EnvironmentValues {
    var hideNotch: () -> () {
        get { self[HideNotchKey.self] }
        set { self[HideNotchKey.self] = newValue }
    }
}
