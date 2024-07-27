//
//  MultilineTextField.swift
//  NotchNook
//
//  Created by Lori Montenegro on 27/07/24.
//

import SwiftUI

struct MultilineTextField: View {
    @Binding var text: String
    var onCommit: (() -> Void)?
    
    private let minHeight: CGFloat = 18
    private let maxHeight: CGFloat = 40
    
    @State private var height: CGFloat = 18
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .frame(height: height)
            .font(.caption)
            .focused($isFocused)
            .onChange(of: text) { newValue in
                doAfter {
                    recalculateHeight()
                }
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
                }
            }
            .border(Color(red: 0.23, green: 0.61, blue: 0.9, opacity: 0.6), width: 2.5)
            .multilineTextAlignment(.center)
            .cornerRadius(3.0)
            .disableAutocorrection(true)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func recalculateHeight() {
        let newHeight = text.heightWithConstrainedWidth(width: 56, font: .caption)
        height = min(max(newHeight, minHeight), maxHeight)
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
