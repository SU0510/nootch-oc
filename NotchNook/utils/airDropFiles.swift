//
//  airDropFiles.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import AppKit

func airDropItems(items: [URL]) {
    let itemsToShare = items.compactMap { url -> Any? in
        url.isFileURL ? url : nil
    }
    
    guard !itemsToShare.isEmpty else {
        print("No file URLs to share via AirDrop")
        return
    }
    
    let sharingService = NSSharingService(named: NSSharingService.Name.sendViaAirDrop)!
    sharingService.perform(withItems: itemsToShare)
}
