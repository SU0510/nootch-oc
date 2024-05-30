//
//  BlankView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct BlankView: View {
    var message: String = "Nothing selected"
    var body: some View {
        VStack {
            Image(systemName: "cloud.fill")
                .font(.system(size: 32))
            Text(message)
        }
        .foregroundStyle(.primary)
    }
}
