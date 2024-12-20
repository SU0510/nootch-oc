//
//  MediaLiveActivityEffectEnum.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/07/24.
//

import SwiftUI
import Defaults

enum MediaLiveActivityEffectEnum: String, Codable, Defaults.Serializable, Identifiable, CaseIterable {
    var id: String { rawValue }
    
    case audioSpectrograph
    case waves
    case vibratingCircle
    case gif
    
    var name: String {
        switch self {
            case .audioSpectrograph: "Audio Spectrograph"
            case .waves: "Waves"
            case .vibratingCircle: "Vibrating Circle"
            case .gif: "GIF"
        }
    }
}
