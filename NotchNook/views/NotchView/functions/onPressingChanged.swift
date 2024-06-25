//
//  onLongPress.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func onLongPress(_ pressing: Bool) {
        if hovering {
            withAnimation(NotchView.intenseAnimation) {
                self.pressing = pressing
            }
        }
    }
}
