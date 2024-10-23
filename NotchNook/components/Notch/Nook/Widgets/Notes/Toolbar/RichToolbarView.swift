//
//  RichToolbarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/06/24.
//

import SwiftUI
import RichTextKit

enum ToolbarButtonStyleKind {
    case widget
    case expanded
}

struct RichToolbarView: View {
    
    @ObservedObject var context: RichTextContext
    @State private var hovering = false
    var buttonStyle: ToolbarButtonStyleKind = .widget
    
    var body: some View {
        let smallFontSize: CGFloat = buttonStyle == .widget ? 13 : 15
        let largeFontSize: CGFloat = buttonStyle == .widget ? 15 : 17
        HStack(spacing: 3) {
            RichToolbarButtonView(
                icon: context.fontSize == smallFontSize ? "textformat.size.smaller" : "character",
                tooltip: "Underline",
                action: {
                    context.fontSize = context.fontSize == smallFontSize ? largeFontSize : smallFontSize
                },
                active: false,
                buttonStyle: buttonStyle
            )
            
            RichToolbarButtonView(
                icon: "bold",
                tooltip: "Bold",
                action: { context.toggleStyle(.bold) },
                active: context.hasStyle(.bold),
                buttonStyle: buttonStyle
            )
            
            RichToolbarButtonView(
                icon: "italic",
                tooltip: "Italic",
                action: { context.toggleStyle(.italic) },
                active: context.hasStyle(.italic),
                buttonStyle: buttonStyle
            )
            
            RichToolbarButtonView(
                icon: "underline",
                tooltip: "Underline",
                action: { context.toggleStyle(.underlined) },
                active: context.hasStyle(.underlined),
                buttonStyle: buttonStyle
            )
        }
        .compositingGroup()
        .onHover { newHovering in
            withAnimation(.easeOut(duration: 0.2)) {
                self.hovering = newHovering
            }
        }
    }
}
