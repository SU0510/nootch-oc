//
//  truncateFileName.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation

func truncateFileName(_ fileName: String, maxLength: Int = 10) -> String {
    // Check if truncation is necessary
    guard fileName.count > maxLength && maxLength > 3 else {
        return fileName
    }
  
    // Base calculations for prefix and suffix length
    let prefixLength = (maxLength - 3) / 2
    let suffixLength = (maxLength - 3) - prefixLength

    // Extract the prefix and suffix
    let prefix = fileName.prefix(prefixLength)
    let suffix = fileName.suffix(suffixLength)
  
    // Creating result with ellipsis
    return "\(prefix)...\(suffix)"
}
