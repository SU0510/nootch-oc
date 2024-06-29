//
//  GetNowKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI
import SwiftDate

private struct GetNowKey: EnvironmentKey {
    static var defaultValue: () -> Date = { Date() }
}

extension EnvironmentValues {
    var getNow: () -> Date {
        get { self[GetNowKey.self] }
        set { self[GetNowKey.self] = newValue }
    }
}
