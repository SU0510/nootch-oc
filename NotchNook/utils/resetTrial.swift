//
//  resetTrial.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/06/24.
//

import Foundation
import Defaults

func resetTrial() {
    Defaults[.trialInitialTime] = nil
}
