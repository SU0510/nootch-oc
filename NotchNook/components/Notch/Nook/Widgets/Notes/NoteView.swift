//
//  NoteView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import RichTextKit

struct NoteView: View {
    var note: Note
    var selected: Bool
    var ns: Namespace.ID
    @State private var text = NSAttributedString(string: "")
    @StateObject var context = RichTextContext()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RichTextEditor(text: $text, context: context)
            RichTextKeyboardToolbar(
                   context: context,
                   leadingButtons: { $0 },
                   trailingButtons: { $0 },
                   formatSheet: { $0 }
               )
        }
        .foregroundStyle(.white)
        .padding(8)
        .frame(maxWidth: selected ? .infinity : 29, maxHeight: selected ? .infinity : 29)
//        .scaleEffect(selected ? 1 : 0.29, anchor: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background { RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.selected.shadow(.drop(radius: 16, y: 8))) }
//        .onChangeDebounced(of: text, delay: 0.5) { newVal in
//            note.text = newVal
//        }
//        .onAppear {
//            text = note.text
//        }
    }
}
