//
//  NSEdgeInsets.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/06/24.
//

import Foundation

extension NSEdgeInsets {
    static let zero = Self(top: 0, left: 0, bottom: 0, right: 0)
    init(_ size: Double) {
        self.init(top: size, left: size, bottom: size, right: size)
    }
}
