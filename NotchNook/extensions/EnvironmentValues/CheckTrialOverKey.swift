//
//  CheckTrialOverKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct CheckTrialOverKey: EnvironmentKey {
    static var defaultValue: () -> () = {}
}

extension EnvironmentValues {
    var checkTrialOver: () -> () {
        get { self[CheckTrialOverKey.self] }
        set { self[CheckTrialOverKey.self] = newValue }
    }
}
