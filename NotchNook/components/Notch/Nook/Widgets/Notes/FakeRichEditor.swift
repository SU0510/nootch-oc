//
//  FakeRichEditor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/07/24.
//

import SwiftUI

struct FakeRichEditor: View {
    var str: AttributedString
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(str)
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: 13, leading: 13, bottom: 40, trailing: 13))
        }
        .coordinateSpace(name: "scroll")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }
}
