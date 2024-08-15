import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileDraggableView<DragPreview: View>: NSViewRepresentable {
    var onSelect: () -> ()
    var onDropCompleted: (Bool) -> ()  // Callback for when drag operation completes
    var selectedURLs: [URL]
    @ViewBuilder var dragPreview: () -> DragPreview
    
    func makeNSView(context: Context) -> CustomDraggableView<DragPreview> {
        let view = CustomDraggableView<DragPreview>()
        view.onSelect = onSelect
        view.onDropCompleted = onDropCompleted
        view.selectedURLs = selectedURLs
        view.dragPreview = dragPreview
        
        // Enable dragging
        view.registerForDraggedTypes([.fileURL, .html, .string, .pdf, .png, .fileContents])

        return view
    }
    
    func updateNSView(_ nsView: CustomDraggableView<DragPreview>, context: Context) {
        nsView.onSelect = onSelect
        nsView.onDropCompleted = onDropCompleted
        nsView.selectedURLs = selectedURLs
        nsView.dragPreview = dragPreview
    }
}

class CustomDraggableView<DragPreviewChild: View>: NSView, NSDraggingSource {
    
    var onSelect: () -> () = {}
    var onDropCompleted: (Bool) -> () = { _ in }
    var selectedURLs: [URL] = []
    var dragPreview: (() -> DragPreviewChild)?
    
    private var initialMouseDownLocation: NSPoint?
    private let minimumDragDistance: CGFloat = 3.0
    
    // MARK: - NSResponder Methods
    
    override func mouseDown(with event: NSEvent) {
        initialMouseDownLocation = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let initialLocation = initialMouseDownLocation else { return }
        
        let currentLocation = event.locationInWindow
        let distance = hypot(currentLocation.x - initialLocation.x, currentLocation.y - initialLocation.y)
        
        if distance >= minimumDragDistance {
            let items = selectedURLs.map { url -> NSDraggingItem in
                getDraggingItem(for: url)
            }
            let session = beginDraggingSession(with: items, event: event, source: self)
            session.draggingFormation = .none
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        onSelect()
    }
    
    // MARK: - Helpers
    
    private func getDraggingItem(for url: URL) -> NSDraggingItem {
        let draggingItem = NSDraggingItem(pasteboardWriter: url as NSURL)
        
        if let dragPreview {
            let previewImage = renderPreview(dragPreview)
            draggingItem.setDraggingFrame(self.bounds, contents: previewImage)
        } else {
            draggingItem.setDraggingFrame(self.bounds, contents: url as NSURL)
        }
        
        return draggingItem
    }
    
    private func renderPreview(_ preview: () -> DragPreviewChild) -> NSImage {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
        let renderer = ImageRenderer(content: preview())
        renderer.scale = scaleFactor
        return renderer.nsImage!
    }
    
    // MARK: - NSDraggingSource Methods
    
    func draggingSession(_ session: NSDraggingSession, endedAt point: NSPoint, operation: NSDragOperation) {
        let didMoveFile = operation == .move
        onDropCompleted(didMoveFile)
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        [.copy, .move, .link, .generic]
    }
    
    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        session.draggingPasteboard.clearContents()
        for url in selectedURLs {
            session.draggingPasteboard.writeObjects([url as NSURL])
        }
    }
    
    // MARK: - NSDraggingDestination Methods
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let supportedTypes: [NSPasteboard.PasteboardType] = [.fileURL, .string, .html, .png, .pdf]
        
        guard let pasteboardTypes = sender.draggingPasteboard.types,
              pasteboardTypes.contains(where: { supportedTypes.contains($0) }) else {
            return []
        }
        
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            selectedURLs = urls
            onSelect()
            return true
        }
        return false
    }
}
