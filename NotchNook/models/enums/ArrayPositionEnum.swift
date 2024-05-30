//
//  ArrayPositionEnum.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

enum ArrayPosition {
    case first, middle, last, single
    
    init(total: Int, i: Int) {
        if total == 1 { self = .single; return }
        if i == (total - 1) { self = .last; return }
        if i == 0 { self = .first; return }
        self = .middle
    }
}
