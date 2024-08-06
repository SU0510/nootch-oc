//
//  MultilineTextField.swift
//  NotchNook
//
//  Created by Lori Montenegro on 27/07/24.
//

import SwiftUI

struct MultilineTextField: View {
    @Binding var text: String
    @State private var height: CGFloat = 14
    @FocusState private var isFocused: Bool
    @State private var selectedRange: NSRange?
    
    private let minHeight: CGFloat = 14
    private let maxHeight: CGFloat = 28
    
    var body: some View {
        NonHyphenatingTextEditor(text: $text, selectedRange: $selectedRange, isInitialAppearance: $isInitialAppearance)
            .focused($isFocused)
            .frame(height: height)
            .onChange(of: text) {
                doAfter { recalculateHeight() }
            }
            .background(GeometryReader { geo in
                Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
            })
            .onPreferenceChange(ViewHeightKey.self) { height in
                self.height = min(max(height, minHeight), maxHeight)
            }
            .onAppear {
                doAfter {
                    isFocused = true
                    recalculateHeight()
                    selectFileNameWithoutExtension()
                }
            }
            .border(Color(red: 0.23, green: 0.61, blue: 0.9, opacity: 0.6), width: 2.5)
            .cornerRadius(3.0)
    }
    
    private func recalculateHeight() {
        let newHeight = text.heightWithConstrainedWidth(width: 56)
        height = min(max(newHeight, minHeight), maxHeight)
    }
    
    private func selectFileNameWithoutExtension() {
        if let dotIndex = text.lastIndex(of: ".") {
            let startIndex = text.startIndex
            let length = text.distance(from: startIndex, to: dotIndex)
            selectedRange = NSRange(location: 0, length: length)
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct NonHyphenatingTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange?
    @Binding var isInitialAppearance: Bool
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.textContainer?.maximumNumberOfLines = 0
        textView.textContainer?.lineFragmentPadding = 0
        textView.alignment = .center
        textView.font = NSFont.systemFont(ofSize: 10)
        textView.delegate = context.coordinator
        
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
        }
        if isInitialAppearance, let range = selectedRange {
            doAfter {
                nsView.selectedRange = range
                nsView.scrollRangeToVisible(range)
                isInitialAppearance = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NonHyphenatingTextEditor
        
        init(_ parent: NonHyphenatingTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if (commandSelector == #selector(NSStandardKeyBindingResponding.moveLeft(_:)) ||
                commandSelector == #selector(NSStandardKeyBindingResponding.moveRight(_:))) {
                return false // Let the system handle these events
            }
            return false
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.selectedRange = textView.selectedRange()
        }
    }
}
