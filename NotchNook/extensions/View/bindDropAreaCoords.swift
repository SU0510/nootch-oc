//
//  getDropAreaCoords.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI


private struct DropAreaCoordPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}

extension View {
    func bindDropAreaCoords(coordinatedSpace: CoordinateSpace, _ value: Binding<CGRect>) -> some View {
        self
            .background(
                GeometryReader { geo in
                    let rect = geo.frame(in: coordinatedSpace)
                    Color.clear
                        .preference(key: DropAreaCoordPreferenceKey.self, value: rect)
                }
            )
            .onPreferenceChange(DropAreaCoordPreferenceKey.self, perform: {
                value.wrappedValue = $0
            })
    }
}
