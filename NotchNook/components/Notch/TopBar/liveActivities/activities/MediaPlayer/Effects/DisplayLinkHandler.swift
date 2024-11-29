//
//  DisplayLinkHandler.swift
//  NotchNook
//
//  Created by Lori Montenegro on 29/11/24.
//

import SwiftUI

class DisplayLinkHandler {
    private weak var target: AnyObject?
    private var displayLink: CVDisplayLink?
    private let updateBlock: () -> Void
    private var lastUpdate: TimeInterval = 0
    private let interval: TimeInterval
    
    init<T: AnyObject>(target: T, fps: Int = 60, update: @escaping () -> Void) {
        self.target = target
        self.updateBlock = update
        self.interval = 1.0 / TimeInterval(fps)
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink = displayLink else { return }
        
        let callback: CVDisplayLinkOutputCallback = { (_, _, _, _, _, contextInfo) -> CVReturn in
            guard let context = contextInfo else { return kCVReturnError }
            let handler = Unmanaged<DisplayLinkHandler>.fromOpaque(context).takeUnretainedValue()
            
            let currentTime = CACurrentMediaTime()
            if currentTime - handler.lastUpdate >= handler.interval {
                handler.lastUpdate = currentTime
                if handler.target != nil {
                    DispatchQueue.main.async {
                        handler.updateBlock()
                    }
                }
            }
            return kCVReturnSuccess
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, callback, context)
    }
    
    func start() {
        guard let displayLink = displayLink, !CVDisplayLinkIsRunning(displayLink) else { return }
        lastUpdate = CACurrentMediaTime()
        CVDisplayLinkStart(displayLink)
    }
    
    func stop() {
        guard let displayLink = displayLink, CVDisplayLinkIsRunning(displayLink) else { return }
        CVDisplayLinkStop(displayLink)
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            CVDisplayLinkSetOutputCallback(displayLink, nil, nil)
        }
    }
}
