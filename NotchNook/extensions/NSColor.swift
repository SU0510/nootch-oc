//
//  NSColor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import Foundation
import AppKit

import Cocoa

extension NSColor {
    var rgb: (CGFloat, CGFloat, CGFloat) {
        let red = self.redComponent
        let green = self.greenComponent
        let blue = self.blueComponent
        return (red, green, blue)
    }
    
    func lighter(by factor: CGFloat = 0.2) -> NSColor? {
        guard let rgbColor = self.usingColorSpace(.deviceRGB) else {
            return nil
        }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        rgbColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = min(brightness + factor, 1.0)
        
        return NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}
