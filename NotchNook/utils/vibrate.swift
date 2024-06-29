//
//  vibrate.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import Foundation
import Defaults
import AppKit

private let inMemoryGeneralSettings = InMemoryDefault(key: .generalSettings)

func vibrate() {
    if inMemoryGeneralSettings.value.disableHaptics { return }
    NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
}
