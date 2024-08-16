//
//  SparkleManagerKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

#if !SETAPP_BUILD
private struct SparkleManagerKey: EnvironmentKey {
    static var defaultValue = SparkleManager(updaterController: nil)
}

extension EnvironmentValues {
    var sparkleManager: SparkleManager {
        get { self[SparkleManagerKey.self] }
        set { self[SparkleManagerKey.self] = newValue }
    }
}
#endif
