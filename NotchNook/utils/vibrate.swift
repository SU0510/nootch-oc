//
//  vibrate.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import Foundation
import Defaults
import AppKit

func vibrate() {
    if Defaults[.generalSettings].disableHaptics { return }
    NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
}
