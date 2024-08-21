//
//  ShowIndicatorKey.swift
//  NotchNook
//
//  Created by Lori Montenegro on 20/08/24.
//

import SwiftUI

extension EnvironmentValues {
    var showIndicator: (Indicator?) -> Void {
        get { self[ShowIndicatorKey.self] }
        set { self[ShowIndicatorKey.self] = newValue }
    }
}

struct ShowIndicatorKey: EnvironmentKey {
    static let defaultValue: (Indicator?) -> Void = { _ in }
}
