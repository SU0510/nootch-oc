//
//  ShowChangelogKey.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

private struct ShowChangelogKey: EnvironmentKey {
    static var defaultValue: () -> () = { }
}

extension EnvironmentValues {
    var showChangelog: () -> () {
        get { self[ShowChangelogKey.self] }
        set { self[ShowChangelogKey.self] = newValue }
    }
}
