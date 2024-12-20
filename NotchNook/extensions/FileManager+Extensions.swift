//
//  FileManager+Extensions.swift
//  NotchNook
//
//  Created by Lori Montenegro on 16/12/24.
//

import SwiftUI

extension FileManager {
    var customGifURL: URL? {
        guard let documentsDirectory = urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let gifDirectory = documentsDirectory.appendingPathComponent("CustomGIF", isDirectory: true)
        
        // Look for any .gif file in the directory
        let contents = try? contentsOfDirectory(at: gifDirectory, includingPropertiesForKeys: nil)
        return contents?.first { $0.pathExtension == "gif" }
    }
    
    func saveCustomGIF(from sourceURL: URL) throws {
        guard let documentsDirectory = urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "GIFError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let gifDirectory = documentsDirectory.appendingPathComponent("CustomGIF", isDirectory: true)
        
        // Generate random filename
        let randomFilename = "\(UUID().uuidString).gif"
        let newURL = gifDirectory.appendingPathComponent(randomFilename)
        
        try? createDirectory(at: gifDirectory, withIntermediateDirectories: true)
        
        // Remove any existing GIF files
        if let contents = try? contentsOfDirectory(at: gifDirectory, includingPropertiesForKeys: nil) {
            for url in contents where url.pathExtension == "gif" {
                try? removeItem(at: url)
            }
        }
        
        // Copy new file
        try copyItem(at: sourceURL, to: newURL)
    }
    
    func removeCustomGIF() {
        guard let url = customGifURL else { return }
        try? removeItem(at: url)
    }
}
