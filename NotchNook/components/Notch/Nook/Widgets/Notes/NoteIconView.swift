//
//  NoteIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 30/06/24.
//

import SwiftUI

struct NoteIconView: View {
    let noteId: String
    let icon: String
    let downScaled: Bool
    let ns: Namespace.ID
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .frame(24)
            .padding(downScaled ? 2 : 4)
            .foregroundStyle(.blue)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 0)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            .scaleEffect(downScaled ? 0.75 : 1, anchor: .bottomTrailing)
            .transition(.scale(1))
            .matchedGeometryEffect(id: "\(noteId)-note-icon", in: ns, properties: [.position])
            .opacity(downScaled ? 0.65 : 1)
    }
}
