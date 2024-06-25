//
//  hideNotch.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func hideNotch() {
        if notchNook.hidden { return }
        withAnimation(.smooth) { notchNook.hidden = true }
    }
}
