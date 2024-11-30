//
//  ShowIndicatorKey.swift
//  NotchNook
//
//  Created by Lori Montenegro on 20/08/24.
//

import SwiftUI

extension EnvironmentValues {
    var showIndicator: (Indicator?, _ onAllScreens: Bool) -> Void {
        get { self[ShowIndicatorKey.self] }
        set { self[ShowIndicatorKey.self] = newValue }
    }
}

struct ShowIndicatorKey: EnvironmentKey {
    static let defaultValue: (Indicator?, _ onAllScreens: Bool) -> Void = { (_, _) in }
}
