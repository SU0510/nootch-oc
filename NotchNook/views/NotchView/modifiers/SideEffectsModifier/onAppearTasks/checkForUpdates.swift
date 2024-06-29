//
//  checkForUpdates.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.SideEffectsModifier {
    func checkForUpdates() {
        if sparkleManager.automaticallyChecksForUpdates {
            sparkleManager.checkForUpdatesInBackground()
        }
    }
}
