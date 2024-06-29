//
//  paddingDependingOnArrPos.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

extension View {
    func paddingDependingOnArrPos(arrayPosition: ArrayPosition, padding: Double) -> some View {
        self
            .padding(EdgeInsets(
                top: 0,
                leading: arrayPosition == .first ? 0 : padding,
                bottom: 0,
                trailing: arrayPosition == .last ? 0 : padding
            ))
    }
}
