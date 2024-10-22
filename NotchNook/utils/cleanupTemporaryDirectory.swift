//
//  cleanupTemporaryDirectory.swift
//  NotchNook
//
//  Created by Lori Montenegro on 11/09/24.
//

import Foundation

func cleanupTemporaryDirectory(_ tempDirectory: URL? = nil) {
    
    let fileManager = FileManager.default
    let tempParentDirectory = fileManager.temporaryDirectory
    let tempDirectory = tempDirectory ?? tempParentDirectory.appendingPathComponent("NotchNookTemp")
    
    do {
        // Remove the specified temporary directory
        if fileManager.fileExists(atPath: tempDirectory.path) {
            try fileManager.removeItem(at: tempDirectory)
            print("Specific temporary directory removed successfully")
        }
    } catch {
        print("Error removing specific temporary directory: \(error)")
    }
    
    do {
        // Remove temporary directories matching the pattern (the code that was adding these directoried was already removed so this is for removing the directories that were previously created)
        let contents = try fileManager.contentsOfDirectory(at: tempParentDirectory, includingPropertiesForKeys: nil, options: [])
        let pattern = "^TemporaryDirectory\\.[a-zA-Z0-9]{5,6}$"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        
        for url in contents {
            let name = url.lastPathComponent
            let range = NSRange(location: 0, length: name.utf16.count)
            if regex.firstMatch(in: name, options: [], range: range) != nil {
                do {
                    try fileManager.removeItem(at: url)
                    print("Removed temporary directory: \(name)")
                } catch {
                    print("Error removing temporary directory \(name): \(error)")
                }
            }
        }
    } catch {
        print("Error accessing or processing temporary directories: \(error)")
    }
}
