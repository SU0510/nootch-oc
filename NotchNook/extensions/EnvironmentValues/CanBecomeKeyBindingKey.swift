//
//  CanBecomeKeyBindingKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct CanBecomeKeyBindingKey: EnvironmentKey {
    static var defaultValue: Binding<Bool> = .init {
        false
    } set: { _ in
        
    }
}

extension EnvironmentValues {
    var canBecomeKey: Binding<Bool> {
        get { self[CanBecomeKeyBindingKey.self] }
        set { self[CanBecomeKeyBindingKey.self] = newValue }
    }
}
