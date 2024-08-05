//
//  NookWidgetsWidthKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/07/24.
//

import SwiftUI

private struct NookWidgetsWidthKey: EnvironmentKey {
    static var defaultValue: NookGrid.Point = .zero
}

extension EnvironmentValues {
    var nookWidgetsWidth: NookGrid.Point {
        get { self[NookWidgetsWidthKey.self] }
        set { self[NookWidgetsWidthKey.self] = newValue }
    }
}
