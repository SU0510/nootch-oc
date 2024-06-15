//
//  ShelfIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct ShelfIconView: View {
    var body: some View {
        Image(systemName: LiveActivity.shelf.icon)
            .font(.system(size: 13))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
    }
}

