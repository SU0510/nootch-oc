//
//  iconForFile.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import SwiftUI
import AppKit

func iconForFile(at fileURL: URL) -> Image {
    let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
    return Image(nsImage: icon)
}
