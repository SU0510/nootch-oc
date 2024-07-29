//
//  VolumeAndBrightnessListenerKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/07/24.
//

import SwiftUI

private struct VolumeAndBrightnessListenerKey: EnvironmentKey {
    static var defaultValue = VolumeAndBrightnessListener()
}

extension EnvironmentValues {
    var volumeAndBrightnessListener: VolumeAndBrightnessListener {
        get { self[VolumeAndBrightnessListenerKey.self] }
        set { self[VolumeAndBrightnessListenerKey.self] = newValue }
    }
}
