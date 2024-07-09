//
//  Pipeline.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct Pipeline: Identifiable, Equatable {
    static func == (lhs: Pipeline, rhs: Pipeline) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let label: String
    let icon: Image
    var allowedFileTypes: [NSPasteboard .PasteboardType]
    let action: (_ fileURLs: [URL], _ dropAreaCoords: CGRect) -> Void
}

let allPipelines: [Pipeline] = [
    Pipeline(
        id: "airdrop", label: String(localized: "AirDrop"),
        icon: Image(nsImage: NSWorkspace.shared.icon(for: .init("com.apple.airdrop")!)),
        allowedFileTypes: [.fileURL],
        action: { fileURLs, dropAreaCoords in
            airDropFiles(urls: fileURLs)
        }
    )
//    Pipeline(
//        id: "opt-img", label: "Compress", 
//        icon: Image(systemName: "photo.stack.fill"),
//        allowedFileTypes: [.image],
//        action: { fileURLs, dropAreaCoords in
//            
//        }
//    )
]
