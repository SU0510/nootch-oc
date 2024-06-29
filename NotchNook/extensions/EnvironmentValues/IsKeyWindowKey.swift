//
//  IsKeyWindowKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct IsKeyWindowKey: EnvironmentKey {
    static var defaultValue: Bool = true
}

extension EnvironmentValues {
    var isKeyWindow: Bool {
        get { self[IsKeyWindowKey.self] }
        set { self[IsKeyWindowKey.self] = newValue }
    }
}
