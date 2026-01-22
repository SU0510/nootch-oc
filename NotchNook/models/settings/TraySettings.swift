//
//  TraySettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

struct TraySettings: Preferences {
    var size = NookGrid.Size(width: 11, height: 2)
    
    var resolvedSize: NookGrid.Size {
        let nookSettings = Defaults[.nookSettings]
        let nookWidth: NookGrid.Point = nookSettings.enabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }

        return NookGrid.Size(width: max(size.width.value, nookWidth.value), height: 2)
    }
}
