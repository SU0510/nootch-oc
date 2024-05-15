//
//  DropAction.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DropAction: Identifiable, Equatable {
    static func == (lhs: DropAction, rhs: DropAction) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let label: String
    let icon: Image
    var allowedFileTypes: [UTType]
    let action: (_ fileURLs: [URL], _ dropAreaCoords: CGRect) -> Void
}

let allDropActions: [DropAction] = [
    DropAction(
        id: "airdrop", label: "AirDrop",
        icon: Image(nsImage: NSWorkspace.shared.icon(forFileType: "com.apple.airdrop")),
        allowedFileTypes: [.fileURL],
        action: { fileURLs, dropAreaCoords in
            airDropFiles(urls: fileURLs)
        }
    ),
    DropAction(
        id: "opt-img", label: "Compress", 
        icon: Image(systemName: "photo.stack.fill"),
        allowedFileTypes: [.image],
        action: { fileURLs, dropAreaCoords in
            
        }
    )
]
