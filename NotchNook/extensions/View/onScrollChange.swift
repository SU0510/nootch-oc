//
//  onScrollChange.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

extension View {
    func onScrollChange(onChange: @escaping (CGFloat) -> Void) -> some View {
        self.background(GeometryReader {
            Color.clear.preference(key: ViewOffsetKey.self,
                value: -$0.frame(in: .named("scroll")).origin.y)
        })
        .onPreferenceChange(ViewOffsetKey.self, perform: onChange)
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
