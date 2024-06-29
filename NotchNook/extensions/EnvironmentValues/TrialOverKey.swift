//
//  TrialOverKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct TrialOverKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var trialOver: Bool {
        get { self[TrialOverKey.self] }
        set { self[TrialOverKey.self] = newValue }
    }
}
