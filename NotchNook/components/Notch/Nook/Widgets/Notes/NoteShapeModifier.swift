//
//  NoteShapeModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/07/24.
//

import SwiftUI
import Defaults
import RichTextKit

extension NoteView {
    struct ShapeModifier: ViewModifier {
        var noteId: String
        var hovering: Bool
        var selected: Bool
        var downScaled: Bool
        var widgetArrPosition: ArrayPosition
        var ns: Namespace.ID
        
        @Environment(\.generalSettings) private var generalSettings
        
        func body(content: Content) -> some View {
            content
                .mask {
                    shapeView()
                        .fill(.black.opacity(!hovering || selected ? 1 : 0.75))
                        .matchedGeometryEffect(id: "\(noteId)-note-mask", in: ns)
                }
                .background {
                    shapeView()
                        .fill(.noteBG.opacity(!hovering || selected ? 1 : 0.75).shadow(.drop(radius: downScaled ? 0 : 16, y: downScaled ? 0 : 8)))
                        .matchedGeometryEffect(id: "\(noteId)-note-bg", in: ns)
                }
                .background {
                    shapeView().fill(.black).matchedGeometryEffect(id: "\(noteId)-note-bg-fade-avoider", in: ns)
                }
                .contentShape(shapeView())
        }
        
        @ViewBuilder func shapeView() -> UnevenRoundedRectangle {
            let cornerRadius: Double = !downScaled ? 13 : 8
            let edgeBiggerCornerRadius = NotchShape.maxNotchRadius - generalSettings.contentPadding
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: cornerRadius,
                    bottomLeading: selected && widgetArrPosition == .first ? edgeBiggerCornerRadius : cornerRadius,
                    bottomTrailing: widgetArrPosition == .last && !selected ? edgeBiggerCornerRadius : cornerRadius,
                    topTrailing: cornerRadius
                ),
                style: .continuous
            )
        }
    }
}
