//
//  FileDropView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/06/24.
//

import SwiftUI

struct FileDropView: NSViewRepresentable {
    var dropEntered: ((NSDraggingInfo) -> Void)?
    var dropUpdated: ((NSDraggingInfo, _ mousePos: CGPoint) -> Void)?
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

    class Coordinator: NSObject {
        var parent: FileDropView

        init(_ parent: FileDropView) {
            self.parent = parent
        }

        func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            parent.dropEntered?(sender)
            return .copy
        }

        func draggingUpdated(_ sender: NSDraggingInfo, _ mousePos: CGPoint) {
            parent.dropUpdated?(sender, mousePos)
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
        var dropDelegate: Coordinator?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            let promiseTypes = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
            registerForDraggedTypes([.fileURL] + promiseTypes)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            if sender.draggingSource as? NSView != nil {
                return .copy
            }
            return dropDelegate?.draggingEntered(sender) ?? NSDragOperation()
        }

        override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
            let rawMousePos = sender.draggingLocation
            let screenSize = (self.window?.screen?.frame.size ?? .zero)
            let viewEdges = self.convert(self.bounds, to: nil)
            let xOffset = (screenSize.width - viewEdges.size.width) / 2
            let mousePos = CGPoint(x: rawMousePos.x - xOffset, y: abs(rawMousePos.y - screenSize.height))
            _ = dropDelegate?.draggingUpdated(sender, mousePos)
            return .copy
        }

        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            return dropDelegate?.performDragOperation(sender) ?? false
        }

        override func draggingExited(_ sender: NSDraggingInfo?) {
            dropDelegate?.draggingExited(sender)
        }
    }
}
