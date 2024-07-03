//
//  ExpandedNoteManagerKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 03/07/24.
//

import SwiftUI

private struct ExpandedNoteManagerKey: EnvironmentKey {
    static var defaultValue: ExpandedNoteManager = ExpandedNoteManager()
}

extension EnvironmentValues {
    var expandedNoteManager: ExpandedNoteManager {
        get { self[ExpandedNoteManagerKey.self] }
        set { self[ExpandedNoteManagerKey.self] = newValue }
    }
}
