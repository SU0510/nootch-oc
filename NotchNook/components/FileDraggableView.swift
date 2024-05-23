import SwiftUI
import AppKit

struct FileDraggableView<DragPreview: View>: NSViewRepresentable {
    var onSelect: () -> ()
    var selectedURLs: [URL]
    @ViewBuilder var dragPreview: () -> DragPreview
    
    class CustomView<DragPreviewChild: View>: NSView, NSDraggingSource {
        var onSelect: () -> () = {}
        var selectedURLs: [URL] = []
        var dragPreview: (() -> DragPreviewChild)?
        
        private var initialMouseDownLocation: NSPoint?
        private let minimumDragDistance: CGFloat = 3.0
        
        override func mouseDown(with event: NSEvent) {
            onSelect()
            initialMouseDownLocation = event.locationInWindow
//            event.
//            super.mouseDown(with: event)
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let initialLocation = initialMouseDownLocation else { return }
            
            let currentLocation = event.locationInWindow
            let distance = hypot(currentLocation.x - initialLocation.x, currentLocation.y - initialLocation.y)
            
            if distance >= minimumDragDistance {
                let items = selectedURLs.map { url -> NSDraggingItem in
                    let pasteboardItem = NSPasteboardItem()
                    pasteboardItem.setString(url.absoluteString, forType: .fileURL)
                    let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
                    
                    if let dragPreview {
                        let previewImage = renderPreview(dragPreview)
                        draggingItem.setDraggingFrame(.init(origin: self.bounds.origin, size: self.bounds.size), contents: previewImage)
                    }
                    
                    return draggingItem
                }
                beginDraggingSession(with: items, event: event, source: self)
            }
        }
        
        func snapshot() -> NSImage {
            let rep = bitmapImageRepForCachingDisplay(in: bounds)!
            cacheDisplay(in: bounds, to: rep)
            let image = NSImage(size: bounds.size)
            image.addRepresentation(rep)
            return image
        }
        
        func renderPreview(_ preview: () -> DragPreviewChild) -> NSImage {
            let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
            let renderer = ImageRenderer(content: preview())
            renderer.scale = scaleFactor
            return renderer.nsImage!
        }
        
        // NSDraggingSource methods
        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            return .move
        }
        
        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            return .move
        }
        
        override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
            return .move
        }
        
        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            return true
        }
    }
    
    func makeNSView(context: Context) -> CustomView<DragPreview> {
        let view = CustomView<DragPreview>()
        view.onSelect = onSelect
        view.selectedURLs = selectedURLs
        view.dragPreview = dragPreview
        
        // Enable dragging
        view.registerForDraggedTypes([.fileURL])
        
        return view
    }
    
    func updateNSView(_ nsView: CustomView<DragPreview>, context: Context) {
        nsView.onSelect = onSelect
        nsView.selectedURLs = selectedURLs
        nsView.dragPreview = dragPreview
        //            let hostingView = NSHostingView(rootView: dragPreview())
        //            hostingView.frame = nsView.bounds
        //            return hostingView
        //        }
    }
}
