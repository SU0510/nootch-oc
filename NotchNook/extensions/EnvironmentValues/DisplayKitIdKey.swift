//
//  DisplayKitIdKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 14/07/24.
//

import SwiftUI

private struct DisplayKitIdKey: EnvironmentKey {
    static var defaultValue = UUID()
}

extension EnvironmentValues {
    var displayKitId: UUID {
        get { self[DisplayKitIdKey.self] }
        set { self[DisplayKitIdKey.self] = newValue }
    }
}
