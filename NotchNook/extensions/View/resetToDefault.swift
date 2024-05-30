//
//  resetToDefault.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI

extension View {
    func resetToDefault<C>(_ value: Binding<C>, _ defaultValue: C) -> some View {
        self
            .contentShape(Rectangle())
            .contextMenu {
                Button("Reset to default") {
                    value.wrappedValue = defaultValue
                }
            }
    }
}
