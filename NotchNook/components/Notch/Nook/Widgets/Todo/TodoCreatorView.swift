//
//  TodoCreatorView.swift
//  NotchNook
//

import SwiftUI
import AppKit

// MARK: - Stable-baseline NSTextField
// SwiftUI's plain TextField on macOS is backed by NSTextField + a shared
// field editor (NSTextView). The field editor has a non-zero
// textContainerInset (typically {2,0}) while the cell's own drawingRect
// is flush to its bounds. When focus switches the rendered glyph origin
// shifts by ~1-2 pt — visible as a "jump". Fixing it requires overriding
// `setUpFieldEditorAttributes(_:)` on the cell to zero the inset, and
// setting `focusRingType = .none` so the focus-ring expansion doesn't
// perturb the cell's drawing rect.

private final class StableCell: NSTextFieldCell {
    override func setUpFieldEditorAttributes(_ textObj: NSText) -> NSText {
        let editor = super.setUpFieldEditorAttributes(textObj)
        if let tv = editor as? NSTextView {
            tv.textContainerInset = .zero
        }
        return editor
    }
}

private final class StableTextField: NSTextField {
    override class var cellClass: AnyClass? {
        get { StableCell.self }
        set {}
    }
    override var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }
}

// MARK: - NSViewRepresentable wrapper

private struct StableNSTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String
    var font: NSFont
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> StableTextField {
        let tf = StableTextField()
        tf.placeholderString = placeholder
        tf.font = font
        tf.isBordered = false
        tf.isBezeled = false
        tf.drawsBackground = false
        tf.isEditable = true
        tf.isSelectable = true
        tf.cell?.wraps = false
        tf.cell?.isScrollable = true
        tf.delegate = context.coordinator
        return tf
    }

    func updateNSView(_ nsView: StableTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.font = font
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: StableNSTextField
        init(_ parent: StableNSTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.text = tf.stringValue
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            DispatchQueue.main.async { self.parent.isFocused = true }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            DispatchQueue.main.async { self.parent.isFocused = false }
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

// MARK: - View

struct TodoCreatorView: View {
    @Binding var text: String
    var onSubmit: () -> Void

    @State private var isFocused: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "plus.circle")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary.opacity(0.5))
                .frame(width: 16, height: 18)

            StableNSTextField(
                text: $text,
                isFocused: $isFocused,
                placeholder: NSLocalizedString("New task…", comment: "A placeholder for a new task."),
                font: .systemFont(ofSize: 11.5, weight: .regular),
                onSubmit: onSubmit
            )
            .frame(height: 18)
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
