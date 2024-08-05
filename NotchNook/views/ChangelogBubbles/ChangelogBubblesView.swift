//
//  ChangelogBubblesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/07/24.
//

import SwiftUI

struct ChangelogBubblesView: View {
    var body: some View {
        HStack(spacing: 32) {
            ChangelogBubbleView()
            ChangelogBubbleView()
            ChangelogBubbleView()
        }
    }
}
