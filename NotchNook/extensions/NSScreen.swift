//
//  UIView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import AppKit

extension NSScreen {
    var hasTopNotchDesign: Bool {
        guard #available(macOS 12, *) else { return false }
        return safeAreaInsets.top != 0
    }
}
