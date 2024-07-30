//
//  Indicator.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/07/24.
//

import SwiftUI

struct Indicator: Identifiable, Equatable, Hashable {
    var id = UUID()
    let kind: Kind
    let icon: String? = nil
    let value: Double
    
    enum Kind: String, Hashable {
        case brightness, volume
    }
}
