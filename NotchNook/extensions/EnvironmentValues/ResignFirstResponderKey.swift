//
//  ResignFirstResponderKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct ResignFirstResponderKey: EnvironmentKey {
    static var defaultValue: () -> () = {}
}

extension EnvironmentValues {
    var resignFirstResponder: () -> () {
        get { self[ResignFirstResponderKey.self] }
        set { self[ResignFirstResponderKey.self] = newValue }
    }
}
