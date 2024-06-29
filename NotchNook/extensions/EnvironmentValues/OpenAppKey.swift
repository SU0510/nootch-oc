//
//  OpenAppKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct OpenAppKey: EnvironmentKey {
    static var defaultValue: (_ bundleId: String) -> () = { _ in }
}

extension EnvironmentValues {
    var openApp: (_ bundleId: String) -> () {
        get { self[OpenAppKey.self] }
        set { self[OpenAppKey.self] = newValue }
    }
}
