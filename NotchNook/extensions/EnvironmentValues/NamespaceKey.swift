//
//  NamespaceKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct NamespaceKey: EnvironmentKey {
    // FIXME: Evaluating Namespace().wrappedValue as a static default triggers a runtime
    // warning "Reading a Namespace property outside View.body". This is a structural
    // limitation of EnvironmentKey requiring a default value; fixing it would require
    // making the environment value optional (Namespace.ID?) and updating all call sites.
    static var defaultValue: Namespace.ID = Namespace().wrappedValue
}

extension EnvironmentValues {
    var namespace: Namespace.ID {
        get { self[NamespaceKey.self] }
        set { self[NamespaceKey.self] = newValue }
    }
}
