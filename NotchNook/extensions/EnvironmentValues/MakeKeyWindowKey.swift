//
//  MakeKeyWindowKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct MakeKeyWindowKey: EnvironmentKey {
    static var defaultValue: () -> () = {}
}

extension EnvironmentValues {
    var makeKeyWindow: () -> () {
        get { self[MakeKeyWindowKey.self] }
        set { self[MakeKeyWindowKey.self] = newValue }
    }
}
