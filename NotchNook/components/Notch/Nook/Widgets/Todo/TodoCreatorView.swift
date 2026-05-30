//
//  TodoCreatorView.swift
//  NotchNook
//

import SwiftUI
import SwiftData

struct TodoCreatorView: View {
    @Binding var text: String
    var onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "plus.circle")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary.opacity(0.5))
                .frame(width: 16, height: 18)

            TextField("New task…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11.5, weight: .regular))
                .focused($isFocused)
                .frame(height: 18)
                .onSubmit {
                    onSubmit()
                }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white.opacity(isFocused ? 0.18 : 0), lineWidth: 1)
        )
    }
}
