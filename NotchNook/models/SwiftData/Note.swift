//
//  Note.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI
import SwiftData

@Model
final class Note {
    var note: String = ""
    var createdAt: Date
    var updatedAt: Date
    
    init(timestamp: Date) {
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
