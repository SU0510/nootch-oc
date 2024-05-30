//
//  WidgetPrefs.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

protocol WidgetPrefs: Preferences {
    var size: Grid.Size { get set }
}
