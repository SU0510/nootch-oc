//
//  FileDropView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/06/24.
//

import SwiftUI

struct FileDropView: NSViewRepresentable {
    var dropEntered: ((NSDraggingInfo) -> Void)?
    var dropUpdated: ((NSDraggingInfo) -> Void)?
    var performDrop: ((NSDraggingInfo) -> Bool)?
    var dropExited: ((NSDraggingInfo) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = DropAreaView()
        view.dropDelegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSDraggingDestination {
        var parent: FileDropView

        init(_ parent: FileDropView) {
            self.parent = parent
        }

        func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            parent.dropEntered?(sender)
            return .copy
        }

        func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
            parent.dropUpdated?(sender)
            return .copy
        }

        func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            return parent.performDrop?(sender) ?? false
        }

        func draggingExited(_ sender: NSDraggingInfo?) {
            if let sender = sender {
                parent.dropExited?(sender)
            }
        }
    }

    class DropAreaView: NSView {
        var dropDelegate: NSDraggingDestination?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            registerForDraggedTypes([.fileURL])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            return dropDelegate?.draggingEntered?(sender) ?? NSDragOperation()
        }

        override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
            return dropDelegate?.draggingUpdated?(sender) ?? NSDragOperation()
        }

        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            return dropDelegate?.performDragOperation?(sender) ?? false
        }

        override func draggingExited(_ sender: NSDraggingInfo?) {
            dropDelegate?.draggingExited?(sender)
        }
    }
}
