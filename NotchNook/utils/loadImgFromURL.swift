//
//  loadImgFromURL.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

import Cocoa

func loadImgFromURL(_ url: URL) -> Image? {
    if url.isImg {
        if let image = NSImage(contentsOf: url) {
            return Image(nsImage: image)
        } else {
            print("Failed to load image from URL")
        }
    }

    return nil
}
