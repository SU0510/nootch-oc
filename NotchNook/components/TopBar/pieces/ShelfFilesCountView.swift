//
//  ShelfFilesCountView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct ShelfFilesCountView: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("\(Shelf.shared.files.count)")
            Image(systemName: NotchNook.shared.activeLiveActions.count > 1 ? "shippingbox.fill" : "doc.fill")
        }
        .frame(maxWidth: .infinity)
        .font(.system(size: 13))
        .foregroundStyle(.white)
    }
}
