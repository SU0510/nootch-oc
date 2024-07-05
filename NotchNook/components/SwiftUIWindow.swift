//
//  SwiftUIWindow.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/06/24.
//

import SwiftUI
import AppKit
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

class SwiftUIAnimatedWindow<Content>: BetterWindow where Content: View {
    private var viewBuilder: () -> Content {
        didSet {
            guard let hostingView = self.contentView as? NSHostingView<Content> else { return }
            hostingView.rootView = viewBuilder()
        }
    }
    
    init(contentRect: NSRect = .zero, styleMask: NSWindow.StyleMask = [], backing: NSWindow.BackingStoreType = .buffered, defer doDefer: Bool = true, @ViewBuilder viewBuilder: @escaping () -> Content) {
        self.viewBuilder = viewBuilder
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: doDefer)
    }
    
    func show() {
        let contentView = viewBuilder()
        let view = NSHostingView(rootView: contentView)
        
        let intrinsicSize = view.intrinsicContentSize
//        let screenF = self.screen?.frame.size ?? .zero
        self.contentView = view
        var finalSize = intrinsicSize
        if self.toolbar != nil {
            finalSize.height += 51  // Add toolbar height if present
        }
        self.setContentSize(finalSize)
        self.center()
        self.setFrameOrigin(.init(x: self.frame.origin.x, y: self.frame.origin.x - 200))

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return }
        blurFilter.name = "blur"
        
        let blurAnimation = getSpringAnimation("filters.blur.inputRadius", from: 120, to: 0)
        let scaleX1Animation = getSpringAnimation("transform.scale.x", from: 0.01, to: 0.35, m: 0.25)
        let scaleX2Animation = getSpringAnimation("transform.scale.x", from: nil, to: 1, m: 0.25)
        let scaleYAnimation = getSpringAnimation("transform.scale.y", from: 0.35, to: 1)
        let rotationAnimation = getSpringAnimation("transform.rotation.z", from: 5.radians, to: 0.radians)
        let positionYAnimation = getSpringAnimation("position.y")
        scaleX2Animation.beginTime = CACurrentMediaTime() + (scaleX1Animation.duration / 5 )
        
        var x = 0.0
        var y = 0.0
        
        doAfter {
            self.makeKeyAndOrderFront(withDuration: 0.45, timing: nil) { layer in
                layer.filters = [blurFilter]
                layer.setValue(120, forKeyPath: "filters.blur.inputRadius")
                
                let oldAnchorPoint = layer.anchorPoint
                layer.anchorPoint = CGPoint(x: 0.65, y: 1)
                let newPoint = CGPoint(x: layer.bounds.size.width * (layer.anchorPoint.x - oldAnchorPoint.x),
                                       y: layer.bounds.size.height * (layer.anchorPoint.y - oldAnchorPoint.y))
                x = layer.position.x + newPoint.x
                y = layer.position.y + newPoint.y
                
                positionYAnimation.fromValue = y + 350
                positionYAnimation.toValue = y
                layer.position = CGPoint(x: x, y: y + 350)
            } animations: { layer in
                layer.add(positionYAnimation, forKey: "positionY")
                layer.add(blurAnimation, forKey: "blur")
                layer.add(scaleX1Animation, forKey: "scaleX1")
                layer.add(scaleX2Animation, forKey: "scaleX2")
                layer.add(rotationAnimation, forKey: "rotation")
                layer.add(scaleYAnimation, forKey: "scaleY")
            }
        }

    }
    
    override func close() {
        var x = 0.0
        var y = 0.0
        self.animatedClose(withDuration: 0.45, timing: nil, setup: { layer in
            layer.filters = [CIFilter(name: "CIGaussianBlur")!]
            layer.setValue(0, forKeyPath: "filters.blur.inputRadius")

            let oldAnchorPoint = layer.anchorPoint
            layer.anchorPoint = CGPoint(x: 0.65, y: 1)
            let newPoint = CGPoint(x: layer.bounds.size.width * (layer.anchorPoint.x - oldAnchorPoint.x),
                                   y: layer.bounds.size.height * (layer.anchorPoint.y - oldAnchorPoint.y))
            x = layer.position.x + newPoint.x
            y = layer.position.y + newPoint.y

            layer.position = CGPoint(x: x, y: y)
        }, animations: { layer in
            let halfScreenW = (self.screen?.frame.size.width ?? 0) / 2
            let hCenterOrigin = self.frame.origin.x + (self.frame.size.width / 2)
            let xOffset = halfScreenW - hCenterOrigin
            let rotationInterpolator = interpolatorBuilder([0, halfScreenW], value: abs(xOffset))
            let rotation = rotationInterpolator([0, 25], true) * (xOffset > 0 ? -1 : 1)
//            let originX = self.frame.origin.x
            
            let blurAnimation = getSpringAnimation("filters.blur.inputRadius", from: 0, to: 120)
            let scaleXAnimation = getSpringAnimation("transform.scale.x", from: 1, to: 0.01)
            let scaleY1Animation = getSpringAnimation("transform.scale.y", from: 1, to: 0.65, m: 0.25)
            let scaleY2Animation = getSpringAnimation("transform.scale.y", from: nil, to: 0.01, m: 0.25)
            let rotationAnimation = getSpringAnimation("transform.rotation.z", from: 0.radians, to: rotation.radians)
            let positionYAnimation = getSpringAnimation("position.y", from: nil, to: y + 350)
            let positionXAnimation = getSpringAnimation("position.x", from: nil, to: x + xOffset)

            scaleY2Animation.beginTime = CACurrentMediaTime() + (scaleY1Animation.duration / 5 )

            layer.add(positionYAnimation, forKey: "positionY")
            layer.add(positionXAnimation, forKey: "positionX")
            layer.add(blurAnimation, forKey: "blur")
            layer.add(scaleY1Animation, forKey: "scaleY1")
            layer.add(scaleY2Animation, forKey: "scaleY2")
            layer.add(scaleXAnimation, forKey: "scaleX")
            layer.add(rotationAnimation, forKey: "rotation")
        })
    }
    
    func windowWillClose(_ notification: Notification) {
        self.contentView = nil
    }
}
