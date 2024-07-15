//
//  BetterWindow.swift
//  NotchNook
//
//  Created by Igor Marcossi on 04/07/24.
//

import SwiftUI
import AppKit
import ScreenCaptureKit

class BetterWindow: NSWindow, NSWindowDelegate, CAAnimationDelegate {
    var whileClosing: (() -> ())?
    var onClose: (() -> ())?
    private var _disableConstrainedWindow = false
    private var fakeFullscreenScreenshotWindow: NSWindow?
    private var fakeFullscreenScreenshotWindowLayer: CALayer?
    private var openTransactions: Int = 0
    
    override init(contentRect: NSRect = .zero, styleMask: NSWindow.StyleMask = [], backing: NSWindow.BackingStoreType = .buffered, defer doDefer: Bool = true) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: doDefer)
        self.delegate = self
    }
    
    // MARK: - Functions
    
    func animatedClose(withDuration duration: CFTimeInterval, timing: CAMediaTimingFunction?, setup: ((CALayer) -> Void)? = nil, animations: @escaping (CALayer) -> Void) {
        setupIfNeeded(with: setup, closing: true) {
            
            self.whileClosing?()
            self.performAnimations(animations, duration: duration, timing: timing) {
                super.close()
                self.onClose?()
            }
        }
    }
    
    func makeKeyAndOrderFront(withDuration duration: CFTimeInterval, timing: CAMediaTimingFunction?, setup: ((CALayer) -> Void)?, animations: @escaping (CALayer) -> Void) {
        setupIfNeeded(with: setup) {
            
            DispatchQueue.main.sync {
                if !self.isVisible {
                    super.makeKeyAndOrderFront(nil)
                }
            }
            
            self.performAnimations(animations, duration: duration, timing: timing)
        }
    }
    
    func takeScreenshot(_ cb: ((CGImage) -> ())? = nil) {
        _disableConstrainedWindow = true
        
//        let isMinimized = self.isMiniaturized
        let onScreen = self.isVisible
        let previousRect = self.frame
        
        if !onScreen {
            self.setFrameOrigin(.init(x: 100000, y: 100000))
            self.makeKeyAndOrderFront(nil)
        }
        
        self.layoutIfNeeded()
        self.contentView?.layoutSubtreeIfNeeded()
        
        DispatchQueue.main.async {
            let windowNumber = self.windowNumber
            let scaleFactor = self.backingScaleFactor
            SCShareableContent.getCurrentProcessShareableContent { shareableContent, error in
                if let error {
                    print("error-tuin")
                    print(error)
                }
                if let scWin = shareableContent?.windows.first(where: { $0.windowID == windowNumber }) {
                    let contentFilter = SCContentFilter(desktopIndependentWindow: scWin)
                    let streamConfig = SCStreamConfiguration()
                    streamConfig.captureResolution = .best
                    streamConfig.ignoreShadowsSingleWindow = true
                    streamConfig.ignoreGlobalClipSingleWindow = true
                    streamConfig.width = Int(previousRect.size.width * scaleFactor)
                    streamConfig.height = Int(previousRect.size.height * scaleFactor)
//                    streamConfig.destinationRect = true
                    streamConfig.showsCursor = false
                    streamConfig.excludesCurrentProcessAudio = true
                    SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: streamConfig) { cgImg, error in
                        if let error {
                            print("error-bleu")
                            print(error)
                        }
                        if let cgImg {
                            DispatchQueue.main.sync {
                                if !onScreen { self.alphaValue = 0.0 }
                                self.setFrameOrigin(previousRect.origin)
                                self._disableConstrainedWindow = false
                            }
                            cb?(cgImg)
                        }
                    }
                }
            }
        }
    }
    
    var shadowRect: CGRect {
        let windowBounds = CGRect(origin: .zero, size: self.frame.size)
        let rect = windowBounds.insetBy(dx: 0.0, dy: 0)
        return rect
    }
    
    var insetBorderRect: CGRect {
        let windowBounds = CGRect(origin: .zero, size: self.frame.size)
        let rect = windowBounds.insetBy(dx: 0, dy: 0)
        return rect
    }
    
    var borderRect: CGRect {
        let windowBounds = CGRect(origin: .zero, size: self.frame.size)
        let rect = windowBounds.insetBy(dx: -0.5, dy: -0.5)
        return rect
    }
    
    func initializeFakeScreenshotWindowLayer() {
        fakeFullscreenScreenshotWindowLayer = CALayer()
        
        guard let fakeFullscreenScreenshotWindowLayer else { return }
        
        fakeFullscreenScreenshotWindowLayer.masksToBounds = false
        fakeFullscreenScreenshotWindowLayer.contentsScale = self.backingScaleFactor
        fakeFullscreenScreenshotWindowLayer.rasterizationScale = self.backingScaleFactor
//        fakeFullscreenScreenshotWindowLayer.shouldRasterize = true
        
        let shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        fakeFullscreenScreenshotWindowLayer.shadowColor = shadowColor
        fakeFullscreenScreenshotWindowLayer.shadowOffset = .init(width: 0, height: -16)
        fakeFullscreenScreenshotWindowLayer.shadowRadius = 20
        fakeFullscreenScreenshotWindowLayer.shadowOpacity = 1.0

        let shadowPath = CGPath(rect: shadowRect, transform: nil)
        fakeFullscreenScreenshotWindowLayer.shadowPath = shadowPath
        
        let insetBorderColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0.2)
        let insetBorderLayer = CALayer()
        insetBorderLayer.frame = insetBorderRect
        insetBorderLayer.borderColor = insetBorderColor
        insetBorderLayer.borderWidth = 1
        insetBorderLayer.cornerRadius = 10
        fakeFullscreenScreenshotWindowLayer.addSublayer(insetBorderLayer)
        
        let borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.95)
        let borderLayer = CALayer()
        borderLayer.frame = borderRect
        borderLayer.borderColor = borderColor
        borderLayer.borderWidth = 0.5
        borderLayer.cornerRadius = 10.5
        fakeFullscreenScreenshotWindowLayer.addSublayer(borderLayer)

        fakeFullscreenScreenshotWindowLayer.contentsGravity = .resize
        fakeFullscreenScreenshotWindowLayer.isOpaque = false
    }
    
    func initializeFakeScreenshotWindow() {
        guard let screen = self.screen else { return }
        fakeFullscreenScreenshotWindow = NSWindow(
            contentRect: CGRect(origin: .zero, size: screen.frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        fakeFullscreenScreenshotWindow?.animationBehavior = .none
        fakeFullscreenScreenshotWindow?.backgroundColor = .clear
        fakeFullscreenScreenshotWindow?.isMovableByWindowBackground = false
        fakeFullscreenScreenshotWindow?.ignoresMouseEvents = false
        fakeFullscreenScreenshotWindow?.level = level
        fakeFullscreenScreenshotWindow?.hasShadow = false
        fakeFullscreenScreenshotWindow?.isOpaque = false
        fakeFullscreenScreenshotWindow?.contentView = AnimatableWindowContentView(frame: .zero)
    }
    
    func setupIfNeeded(with setupBlock: ((CALayer) -> Void)?, closing: Bool = false, cb: @escaping () -> ()) {
        guard self.fakeFullscreenScreenshotWindowLayer == nil else { return }

        initializeFakeScreenshotWindow()
        initializeFakeScreenshotWindowLayer()
        
        guard let fakeFullscreenScreenshotWindow, let fakeFullscreenScreenshotWindowLayer else { return }
        
        
        let frame = self.convertWindowFrameToScreenFrame(self.frame)
        fakeFullscreenScreenshotWindowLayer.frame = frame
        
        guard let layer = fakeFullscreenScreenshotWindow.contentView?.layer else { return }
        layer.addSublayer(fakeFullscreenScreenshotWindowLayer)

        takeScreenshot { image in
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            fakeFullscreenScreenshotWindowLayer.contents = image
            
            setupBlock?(fakeFullscreenScreenshotWindowLayer)
            
            CATransaction.commit()
            
            DispatchQueue.main.sync {
                fakeFullscreenScreenshotWindow.makeKeyAndOrderFront(nil)
                if closing { self.alphaValue = 0.0 }
            }
            
            cb()
        }
    }

    func performAnimations(_ animations: @escaping (CALayer) -> Void, duration: CFTimeInterval, timing: CAMediaTimingFunction?, cb: (() -> ())? = nil) {
        guard let fakeFullscreenScreenshotWindowLayer else { return }

        NSAnimationContext.beginGrouping()
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(timing ?? CAMediaTimingFunction(name: .default))
        CATransaction.setCompletionBlock {
            self.destroyTransformingWindowIfNeeded()
            cb?()
        }
        
        animations(fakeFullscreenScreenshotWindowLayer)
        openTransactions += 1

        CATransaction.commit()
        NSAnimationContext.endGrouping()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        destroyTransformingWindowIfNeeded()
    }

    func destroyTransformingWindowIfNeeded() {
        openTransactions -= 1

        if openTransactions == 0 {
            destroyTransformingWindow()
        }
    }

    func destroyTransformingWindow() {
        self.alphaValue = 1.0

        self.fakeFullscreenScreenshotWindowLayer?.removeFromSuperlayer()
        self.fakeFullscreenScreenshotWindowLayer?.contents = nil
        self.fakeFullscreenScreenshotWindowLayer = nil
            
        self.fakeFullscreenScreenshotWindow?.orderOut(nil)
        self.fakeFullscreenScreenshotWindow = nil
    }
    
    func convertWindowFrameToScreenFrame(_ windowFrame: CGRect) -> CGRect {
        return CGRect(
            x: windowFrame.origin.x - (self.screen?.frame.origin.x ?? 0),
            y: windowFrame.origin.y - (self.screen?.frame.origin.y ?? 0),
            width: windowFrame.size.width,
            height: windowFrame.size.height
        )
    }
    
    
    // MARK: - Overridings
    
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return _disableConstrainedWindow ? frameRect : super.constrainFrameRect(frameRect, to: screen)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}

class AnimatableWindowContentView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = CALayer()
        self.layerUsesCoreImageFilters = true
        self.layerContentsRedrawPolicy = .never
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

import AppKit

func renderLayerToImage(layer: CALayer) -> NSImage? {
    let size = layer.bounds.size
    let image = NSImage(size: size)
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else { return nil }
    layer.render(in: context)
    image.unlockFocus()
    return image
}
