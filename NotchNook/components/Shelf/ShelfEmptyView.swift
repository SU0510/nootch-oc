//
//  ShelfEmptyView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI

struct ShelfEmptyView: View {
    var hovered: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "shippingbox.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
            Text("Box").fontWeight(.medium)
        }
        .foregroundStyle(hovered ? Color.blue : .white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(hovered ? 0.75 : 0.5)
        .transition(.scaleAndBlur)
    }
}
