//
//  SwiftUIWindow.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/06/24.
//

import SwiftUI
import AppKit
import JNWAnimatableWindow
import ScreenCaptureKit

class SwiftUIWindow<Content>: NSWindow, NSWindowDelegate where Content: View {
    private var viewBuilder: () -> Content
    private var onClose: (() -> ())?
    
    init(styleMask: NSWindow.StyleMask, content: @escaping () -> Content, onClose: (() -> ())? = nil) {
        self.viewBuilder = content
        self.onClose = onClose
        super.init(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), styleMask: styleMask, backing: .buffered, defer: true)
        self.delegate = self
    }
    
    func show() {
        let contentView = viewBuilder().environment(\.closeWindow, self.close)
        let view = NSHostingView(rootView: contentView)
        self.contentView = view
        let intrinsicSize = view.intrinsicContentSize
        let screenF = self.screen?.frame.size ?? .zero
        
        var finalSize = intrinsicSize
        if self.toolbar != nil {
            finalSize.height += 51  // Add toolbar height if present
        }
        self.setContentSize(finalSize)
        self.setFrameOrigin(.init(
            x: (screenF.width - finalSize.width) / 2,
            y: (screenF.height - finalSize.height) / 2
        ))
        
        
        self.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        self.contentView = nil
        onClose?()
    }
}

class SwiftUIAnimatedWindow<Content>: JNWAnimatableWindow, NSWindowDelegate where Content: View {
    private var viewBuilder: () -> Content
    private var onClose: (() -> ())?
    
    init(styleMask: NSWindow.StyleMask, content: @escaping () -> Content, onClose: (() -> ())? = nil) {
        self.viewBuilder = content
        self.onClose = onClose
        super.init(contentRect: NSRect(x: 0, y: 0, width: 720, height: 560), styleMask: styleMask, backing: .buffered, defer: false)
        self.delegate = self
    }
    
    func show() {
        let contentView = viewBuilder().environment(\.closeWindow, self.close)
        let view = NSHostingView(rootView: contentView)
        
        let intrinsicSize = view.intrinsicContentSize
        let screenF = self.screen?.frame.size ?? .zero
        self.contentView = view
        var finalSize = intrinsicSize
        if self.toolbar != nil {
            finalSize.height += 51  // Add toolbar height if present
        }
        self.setContentSize(finalSize)
//        self.setFrameOrigin(.init(
//            x: (screenF.width - finalSize.width) / 2,
//            y: (screenF.height - finalSize.height) / 2
//        ))
        self.backgroundColor = .gray
        self.title = "abaca"
//        self.setFrameOrigin(.init(x: 100000, y: 100000))
        

//        self.makeKeyAndOrderFront(nil)
        
        doAfter(0) {
            SCShareableContent.getCurrentProcessShareableContent { shareableContent, error in
                if let noteWin = shareableContent?.windows.first { $0.title == "abaca" } {
                    let contentFilter = SCContentFilter(desktopIndependentWindow: noteWin)
                    let streamConfig = SCStreamConfiguration()
                    streamConfig.captureResolution = .best
                    streamConfig.ignoreGlobalClipSingleWindow = true
                    streamConfig.showsCursor = false
                    streamConfig.excludesCurrentProcessAudio = true
                    SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: streamConfig) { cgImg, error in
                        if let error {
                            print(error)
                        }
                        doAfter(0) {
                        if let cgImg {
                            let nsImg = NSImage(cgImage: cgImg, size: view.intrinsicContentSize)
                            self.contentView = NSHostingView(rootView: ZStack {
                                Image(nsImage: nsImg).resizable().scaledToFit()
                                Text("Amoha")
                            })
                            self.center()
                            self.makeKeyAndOrderFront(nil)
                        }
                        }
                    }
                }
            }
        }
        
        
//        let springTimingFunction = CAMediaTimingFunction(controlPoints: 0.5, 1.1, 0.1, 1.0)
//        self.makeKeyAndOrderFront(withDuration: 1, timing: nil) { layer in
////            let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 1.0])
////            let scaleTransform = CATransform3DMakeScale(0.1, 0.1, 1)
//            layer?.opacity = 0.0
////            layer?.transform = scaleTransform
////            layer?.filters = [blurFilter]
//        } animations: { layer in
////            let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 0])
////            let scaleTransform = CATransform3DMakeScale(1, 1, 1)
//            layer?.opacity = 1.0
////            layer?.transform = scaleTransform
//            //            layer?.filters = [blurFilter]
//        }
//                self.layer.opacity = 0.5
//        doAfter(2) {
//            self.contentView = view
//        }
//                        self.layer.opacity = 0.5
//            doAfter(1) {
//                self.destroyTransformingWindow()
//            }
//            let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 1.0])
//            let scaleTransform = CATransform3DMakeScale(0.1, 0.1, 1)
            //            self.layer.transform = scaleTransform
//            self.layer.filters = [blurFilter]
//        }
//        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.contentView = nil
        onClose?()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}
