//
//  CloseWindowKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct CloseWindowKey: EnvironmentKey {
    static var defaultValue: () -> () = { }
}

extension EnvironmentValues {
    var closeWindow: () -> () {
        get { self[CloseWindowKey.self] }
        set { self[CloseWindowKey.self] = newValue }
    }
}
