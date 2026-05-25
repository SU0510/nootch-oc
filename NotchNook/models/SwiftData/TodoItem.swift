//
//  TodoItem.swift
//  NotchNook
//

import SwiftData
import Foundation

@Model
final class TodoItem {
    var title: String
    var isCompleted: Bool
    var isPriority: Bool
    var createdAt: Date

    init(title: String, isCompleted: Bool = false, isPriority: Bool = false) {
        self.title = title
        self.isCompleted = isCompleted
        self.isPriority = isPriority
        self.createdAt = Date()
    }
}
