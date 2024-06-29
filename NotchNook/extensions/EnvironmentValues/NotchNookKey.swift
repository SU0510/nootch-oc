//
//  NotchNookKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct NotchNookKey: EnvironmentKey {
    static var defaultValue = NotchNook()
}

extension EnvironmentValues {
    var notchNook: NotchNook {
        get { self[NotchNookKey.self] }
        set { self[NotchNookKey.self] = newValue }
    }
}
