//
//  defaultOpenSize.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/05/24.
//

import SwiftUI

extension View {
    func defaultOpenSize(disable: Bool = false, alignment: Alignment = .center) -> some View {
        return self.frame(
            width: disable ? nil : NotchShape.defaultNotchWidth + NotchShape.defaultEstimatedMaxExceedingWidth,
            height: disable ? nil : NotchShape.defaultEstimatedMaxExceedingHeight,
            alignment: alignment
        )
    }
}
