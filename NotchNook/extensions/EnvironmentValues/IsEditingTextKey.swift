//
//  IsEditingTextKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct IsEditingTextKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var isEditingText: Bool {
        get { self[IsEditingTextKey.self] }
        set { self[IsEditingTextKey.self] = newValue }
    }
}
