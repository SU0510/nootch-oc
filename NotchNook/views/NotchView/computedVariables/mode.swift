//
//  mode.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    var mode: NotchNook.NotchMode {
        guard let found = NotchNook.shared.mode[screenID] else {
            NotchNook.shared.mode[screenID] = .closed
            return .closed
        }
        return found
    }
}
