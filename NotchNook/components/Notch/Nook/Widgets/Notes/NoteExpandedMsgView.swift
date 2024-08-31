//
//  NoteExpandedMsgView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 05/07/24.
//

import SwiftUI

struct NoteExpandedMsgView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "bird.fill")
                .font(.system(size: 17))
            VStack {
                Text("The note flew away.")
                Text("Close it to restore.").font(.caption).opacity(0.75)
            }
        }
        .foregroundStyle(.nonShockingWhite.opacity(0.35))
    }
}
