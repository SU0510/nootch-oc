//
//  NoteView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import RichTextKit
import Defaults

struct NoteView: View, Equatable {
    static let smallSize: Double = 29
    static func == (lhs: NoteView, rhs: NoteView) -> Bool {
        lhs.note.persistentModelID == rhs.note.persistentModelID &&
        lhs.selected == rhs.selected &&
        rhs.width == lhs.width &&
        rhs.widgetArrPosition == lhs.widgetArrPosition &&
        rhs.prefs == lhs.prefs &&
        rhs.ns == lhs.ns
    }
    
    var note: Note
    var selected: Bool
    var width: Double
    var widgetArrPosition: ArrayPosition
    var prefs: NotesWidgetSettings
    var ns: Namespace.ID
    @State private var text: NSAttributedString
    @State private var showControls = false
    @State private var downScaled = false
    @State private var hovering = false
    //    @State private var showEditor = false
    @Default(.generalSettings) private var generalSettings
    @StateObject private var context: RichTextContext
    
    init(note: Note, selected: Bool, width: Double, widgetArrPosition: ArrayPosition, prefs: NotesWidgetSettings, ns: Namespace.ID, context: RichTextContext = RichTextContext()) {
        self.note = note
        self.selected = selected
        self.width = width
        self.widgetArrPosition = widgetArrPosition
        self.prefs = prefs
        self.ns = ns
        let context = RichTextContext()
        context.isEditable = selected
        self._text = .init(initialValue: note.text)
        self._context = .init(wrappedValue: context)
        self._downScaled = .init(initialValue: selected)
    }
    
    @ViewBuilder func shapeView() -> UnevenRoundedRectangle {
        let cornerRadius: Double = !downScaled ? 13 : 8
        let edgeBiggerCornerRadius = NotchShape.maxNotchRadius - generalSettings.contentPadding
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: cornerRadius,
                bottomLeading: selected && widgetArrPosition == .first ? edgeBiggerCornerRadius : cornerRadius,
                bottomTrailing: widgetArrPosition == .last ? edgeBiggerCornerRadius : cornerRadius,
                topTrailing: cornerRadius
            ),
            style: .continuous
        )
    }
    
    var body: some View {
//        context
        ZStack(alignment: .bottomTrailing) {
            RichTextEditor(text: $text, context: context) { config in
                if let textView = config as? NSTextView {
                    textView.isEditable = selected
                    textView.backgroundColor = .clear
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakStrategy = .pushOut
                    textView.defaultParagraphStyle = paragraphStyle
                    textView.enclosingScrollView?.hasVerticalScroller = prefs.showScrollIndicator
                    textView.enclosingScrollView?.additionalSafeAreaInsets = NSEdgeInsets(top: 10, left: 10, bottom: 40, right: 10)
                }
            }
            .focusedValue(\.richTextContext, context)
            .frame(width: width - (downScaled ? 0 : 8), height: selected ? nil : 100, alignment: .topLeading)
            .fixedSize(horizontal: true, vertical: !selected)
            .scaleEffect(downScaled ? 0.29 : 1, anchor: .topLeading)
            .padding(downScaled ? 2 : 0)
            .matchedGeometryEffect(id: "\(note.persistentModelID)-note-editor", in: ns, properties: [.position])
            .opacity(downScaled ? 0.25 : 0.9)
            .fadeOnEdges(axis: .vertical, topLeadingFadeLength: 20, bottomTrailingFadeLength: 48, curve: .easeInOut, disable: !selected)
        }
        .richTextEditorConfig(.init(isScrollingEnabled: true, isContinuousSpellCheckingEnabled: false))
        .richTextEditorStyle(.init(font: .systemFont(ofSize: 13), fontColor: .white, backgroundColor: .clear))
        .allowsHitTesting(selected)
        .foregroundStyle(.white)
        .matchedGeometryEffect(id: "\(note.persistentModelID)-note", in: ns)
        .frame(maxWidth: selected ? .infinity : Self.smallSize, maxHeight: selected ? .infinity : Self.smallSize, alignment: .topLeading)
        .overlay(alignment: .bottomTrailing) {
            if selected {
                RichToolbarView(context: context)
                    .padding(4)
                    .scaleEffect(showControls ? 1 : 0.75, anchor: .bottomTrailing)
                    .opacity(showControls ? 1 : 0)
                    .blur(radius: showControls ? 0 : 24)
            }
        }
        .scaleEffect(1)
        .geometryGroup()
        .contentShape(Rectangle())
        .mask {
            shapeView()
                .fill(.black)
                .matchedGeometryEffect(id: "\(note.persistentModelID)-note-mask", in: ns)
        }
        .background {
            shapeView()
                .fill(.noteBG.shadow(.drop(radius: 16, y: 8)))
                .matchedGeometryEffect(id: "\(note.persistentModelID)-note-bg", in: ns)
        }
        .compositingGroup()
        .opacity(hovering || selected ? 1 : 0.75)
        .overlay(alignment: !selected ? .bottomTrailing : .bottomLeading) {
            Image(systemName: note.icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(24)
                .padding(downScaled ? 2 : 4)
                .foregroundStyle(.blue)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 0)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                .scaleEffect(downScaled ? 0.75 : 1, anchor: .bottomTrailing)
                .transition(.scale(1))
                .matchedGeometryEffect(id: "\(note.persistentModelID)-note-icon", in: ns, properties: [.position])
                .opacity(downScaled ? 0.65 : 1)
        }
        .background { shapeView().fill(.black).matchedGeometryEffect(id: "\(note.persistentModelID)-note-bg-fade-avoider", in: ns) }
        .onHover { x in withAnimation(.easeOut) { hovering = x } }
        .animation(.spring, value: widgetArrPosition)
        .onAppear {
            if selected {
                note.updatedAt = Date()
                try? note.modelContext?.save()
            }
            withAnimation(NotesWidgetView.switchAnimation) { downScaled.toggle() }
            withAnimation(.spring.delay(0.3)) { showControls = true }
        }
        .transition(.scale(1))
        .zIndex(selected ? 1 : 0)
        .onReceive(context.objectWillChange) { _ in
            note.text = text
            note.updatedAt = Date()
        }
    }
}
