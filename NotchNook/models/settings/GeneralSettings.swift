//
//  GeneralSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation
import Defaults

struct GeneralSettings: Equatable, Hashable, Codable, Defaults.Serializable {
    var alwaysOpenNotchOnHover = false
}
