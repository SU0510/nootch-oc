//
//  GIFImageView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/07/24.
//

import SwiftUI
import AppKit

struct GIFImageView: NSViewRepresentable {
    
    @Environment(\.mediaLiveActivitySettings) private var settings

    let url: URL
    
    var isPlaying: Bool
    
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.wantsLayer = true
        imageView.animates = isPlaying
        
        if let image = NSImage(contentsOf: url) {
            configureImage(image)
            imageView.image = image
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        imageView.imageScaling = settings.gifScalingQuality.scalingMode
        
        // Apply initial scale transform
        let scale = CGFloat(settings.gifScale)
        imageView.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let image = NSImage(contentsOf: url) {
            configureImage(image)
            nsView.image = image
        }
        nsView.imageScaling = settings.gifScalingQuality.scalingMode
        nsView.animates = isPlaying
        
        DispatchQueue.main.async {
            let scale = CGFloat(settings.gifScale)
            nsView.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        }
    }
    
    private func configureImage(_ image: NSImage) {
        image.isTemplate = false
        
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = settings.gifScalingQuality.interpolation
        }
    }
}
