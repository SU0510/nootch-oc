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
    var allowedFileTypes: [NSPasteboard.PasteboardType]
    let action: (_ fileURLs: [URL], _ dropAreaCoords: CGRect) -> Void
}

let allPipelines: [Pipeline] = [
    Pipeline(
        id: "airdrop",
        label: String(localized: "AirDrop"),
        icon: Image(nsImage: NSWorkspace.shared.icon(for: .init("com.apple.airdrop")!)),
        allowedFileTypes: [
            .fileURL,
            .init("public.url"),
            .init("CorePasteboardFlavorType 0x75726C20"),
            .init("Apple URL pasteboard type"),
            .init("public.utf8-plain-text"),
            .init("NSStringPboardType")
        ],
        action: { fileURLs, dropAreaCoords in
            airDropItems(items: fileURLs)
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
