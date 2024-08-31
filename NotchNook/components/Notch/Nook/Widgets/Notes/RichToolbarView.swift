//
//  RichToolbarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/06/24.
//

import SwiftUI
import RichTextKit

struct RichToolbarView: View {
    var note: Note
    
    @ObservedObject var context: RichTextContext
    @State private var hovering = false
    @Environment(\.expandedNoteManager) private var expandedNoteManager
    @Environment(\.notchNook) private var notchNook
    @Environment(\.displayKitId) private var displayKitId
    
    var body: some View {
        HStack(spacing: 3) {

            let expandedNoteId = "notes-widget"
            RichToolbarButtonView(icon: "arrow.up.left.and.arrow.down.right", tooltip: "Expand", action: {
                notchNook.locked = true
                expandedNoteManager.openNote(note, buttonId: expandedNoteId, displayKitId: displayKitId)
            }, active: false)
            .syncOriginWithExpandedNoteManger(id: expandedNoteId)
            
            RichToolbarButtonView(icon: context.fontSize == 13 ? "textformat.size.smaller" : "character", tooltip: "Underline", action: {
                context.fontSize = context.fontSize == 13 ? 15 : 13
            }, active: false)
            RichToolbarButtonView(icon: "bold", tooltip: "Bold", action: { context.toggleStyle(.bold) }, active: context.hasStyle(.bold))
            RichToolbarButtonView(icon: "italic", tooltip: "Italic", action: { context.toggleStyle(.italic) }, active: context.hasStyle(.italic))
            RichToolbarButtonView(icon: "underline", tooltip: "Underline", action: { context.toggleStyle(.underlined) }, active: context.hasStyle(.underlined))
        }
        .compositingGroup()
        .onHover { newHovering in
            withAnimation(.easeOut(duration: 0.2)) {
                self.hovering = newHovering
            }
        }
    }
}


struct RichToolbarButtonView: View {
    var icon: String
    var tooltip: String
    var action: () -> ()
    var active: Bool
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
        }
        .help(Text(tooltip))
        .buttonStyle(RichToolbarButtonStyle(hovering: hovering, active: active))
        .onHover { hovering = $0 }
    }
}

struct RichToolbarButtonStyle: ButtonStyle {
    var hovering: Bool
    var active: Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        let cornerRadius: Double = 9
        let overColorAlpha: Double = hovering ? ((active ? 0.15 : 0.075) / (configuration.isPressed ? 2 : 1)) : 0
        let overColor: Color = .nonShockingWhite.opacity(overColorAlpha)
        configuration.label
            .foregroundStyle(active ? .lightYellow : .nonShockingWhite.opacity(0.5))
            .font(.system(size: 15, weight: .semibold))
            .frame(24)
            .background(overColor, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
