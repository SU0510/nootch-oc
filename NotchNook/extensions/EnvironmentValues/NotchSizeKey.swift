//
//  NotchSizeKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct NotchSizeKey: EnvironmentKey {
    static var defaultValue: CGSize = .init(width: 184, height: 32)
}

extension EnvironmentValues {
    var notchSize: CGSize {
        get { self[NotchSizeKey.self] }
        set { self[NotchSizeKey.self] = newValue }
    }
}
