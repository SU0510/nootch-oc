//
//  MakeKeyWindowKey.swift
//  NotchNook
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
