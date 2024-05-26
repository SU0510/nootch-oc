//
//  URL.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

extension URL {
    var isImg: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
        let urlExtension = self.pathExtension.lowercased()
        
        return imageExtensions.contains(urlExtension)
    }
}
