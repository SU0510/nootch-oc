//
//  CustomLabeled.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct CustomLabeled<C: View>: View {
    var title: String
    var icon: String? = nil
    var description: String?
    @ViewBuilder var content: () -> C
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
                content()
            }
            if let description {
                Text(.init(description))
                    .font(.caption)
                    .opacity(0.75)
            }
        }
    }
}
