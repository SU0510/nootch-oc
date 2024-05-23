//
//  NotchNook.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import SwiftUI

@Observable
class NotchNook {
    static let shared = NotchNook()
    
    var shelf = Shelf()
    var pinned = false
    var activeLiveActions = Set<LiveAction>()
    var mode: NotchMode = .closed
    
    enum LiveAction: String, Hashable {
        case media, box
    }
    
    enum NotchMode: String, Hashable {
        case closed, nook, shelf, dragging
    }
}

