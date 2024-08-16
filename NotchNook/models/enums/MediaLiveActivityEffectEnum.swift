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
    case gif
    case vibratingCircle
    
    var name: String {
        switch self {
            case .audioSpectrograph: "Audio Spectrograph"
            case .waves: "Waves"
            case .gif: "GIF"
            case .vibratingCircle: "Vibrating Circle"
        }
    }
}
