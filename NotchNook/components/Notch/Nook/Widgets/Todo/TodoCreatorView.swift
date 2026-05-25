//
//  TodoCreatorView.swift
//  NotchNook
//

import SwiftUI
import SwiftData

struct TodoCreatorView: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "plus.circle")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary.opacity(0.5))
                .frame(width: 16)

            TextField("New task…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11.5, weight: .regular))
                .onSubmit {
                    onSubmit()
                }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }
}
