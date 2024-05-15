//
//  airDropFiles.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import AppKit

func airDropFiles(urls: [URL]) {
    let sharingService = NSSharingService(named: NSSharingService.Name.sendViaAirDrop)!
    sharingService.perform(withItems: urls)
}
