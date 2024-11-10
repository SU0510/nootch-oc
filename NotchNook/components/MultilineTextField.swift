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
        TextEditor(text: $text)
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
                    recalculateHeight()
                    selectFileNameWithoutExtension()
                    isFocused = true
                }
            }
            .border(Color(red: 0.23, green: 0.61, blue: 0.9, opacity: 0.6), width: 2.5)
            .clipShape(RoundedRectangle(cornerRadius: 3.0, style: .continuous))
            .multilineTextAlignment(.center)
    }
    
    private func recalculateHeight() {
        let size = text.boundingRect(
            with: CGSize(width: 56, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: NSFont.systemFont(ofSize: 10)],
            context: nil
        )
        height = min(max(size.height, minHeight), maxHeight)
    }
    
    private func selectFileNameWithoutExtension() {
        doAfter(0.15) {
            if let dotIndex = text.lastIndex(of: ".") {
                let startIndex = text.startIndex
                let length = text.distance(from: startIndex, to: dotIndex)
                selectedRange = NSRange(location: 0, length: length)
                
                    if let textView = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
                        textView.selectedRange = selectedRange ?? NSRange()
                    }
            }
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
