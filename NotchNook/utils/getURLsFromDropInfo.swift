//
//  getURLsFromDropInfo.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

func getURLsFromDropInfo(_ info: DropInfo, allowedTypes: [UTType], cb: @escaping (_ urls: [URL]) -> ()) {
    let loadItemGroup = DispatchGroup()
    var actionURLs = [URL]()
    
    for provider in info.itemProviders(for: allowedTypes) {
        loadItemGroup.enter()
        _ = provider.loadObject(ofClass: URL.self) { obj, err in
            if let obj {
                actionURLs.append(obj)
            }
            loadItemGroup.leave()
        }
    }
    
    loadItemGroup.notify(queue: .main) {
        cb(actionURLs)
    }
}
