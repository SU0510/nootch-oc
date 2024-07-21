//
//  GlobalBrightnessAndVolume.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/07/24.
//

import SwiftUI

@Observable
class GlobalBrightnessAndVolume {
    static let shared = GlobalBrightnessAndVolume()
    
    private init(){}
    
    var id = UUID()
    var brightness: Double = 1 { didSet { id = UUID() } }
    var volume: Double = 1 { didSet { id = UUID() } }
}
