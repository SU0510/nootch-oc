//
//  WindowManagerKey.swift
//  NotchNook
//
//  Created by Lori Montenegro on 28/07/24.
//

import SwiftUI

struct EnableTextEditingForWindowWithKey: EnvironmentKey {
    static let defaultValue: (_ id: UUID) -> () = { _ in }
}

struct UpdateEditingTextStateForKey: EnvironmentKey {
    static let defaultValue: (_ id: UUID, _ isEditing: Bool) -> () = { _, _ in }
}

extension EnvironmentValues {
    var enableTextEditingForWindowWith: (_ id: UUID) -> () {
        get { self[EnableTextEditingForWindowWithKey.self] }
        set { self[EnableTextEditingForWindowWithKey.self] = newValue }
    }
    var updateEditingTextStateFor: (_ id: UUID, _ isEditing: Bool) -> () {
        get { self[UpdateEditingTextStateForKey.self] }
        set { self[UpdateEditingTextStateForKey.self] = newValue }
    }
}
