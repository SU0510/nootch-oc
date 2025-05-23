//
//  airDropFiles.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import AppKit

func airDropItems(items: [URL]) {
    let itemsToShare = items.map { url -> Any in
        url.isFileURL ? url : url.absoluteString
    }
    
    let sharingService = NSSharingService(named: NSSharingService.Name.sendViaAirDrop)!
    sharingService.perform(withItems: itemsToShare)
}
