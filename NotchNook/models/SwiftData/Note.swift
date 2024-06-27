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
    var text: String
    var createdAt: Date
    var updatedAt: Date
    
    init(text: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
