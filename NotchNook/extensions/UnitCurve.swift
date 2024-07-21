//
//  UnitCurve.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/07/24.
//

import SwiftUI

extension UnitCurve {
    static let easeInQuint = UnitCurve.bezier(startControlPoint: .init(x: 0.64, y: 0), endControlPoint: .init(x: 0.78, y: 0))
}
