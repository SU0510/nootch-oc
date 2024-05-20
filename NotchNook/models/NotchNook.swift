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
    var notchShapeConfig: NotchShapeConfig = .closed
    var activeLiveActions = Set<LiveAction>()
    var notchMode: NotchMode = .closed
    
    enum LiveAction: String, Hashable {
        case media, box
    }
    
    enum NotchMode {
        case closed, open, shelf, dragging
    }
}

struct NotchShapeConfig: Equatable, Hashable {
    static let closed = Self(height: 0, width: 0, decorationsRadius: 11, notchRadius: 5, shadow: false)
    static let hovering = Self(height: 10, width: 20, decorationsRadius: 22, notchRadius: 14, shadow: true)
    static let pressing = Self(height: 7, width: 14, decorationsRadius: 19, notchRadius: 11, shadow: true)
    static let open = Self(height: 100, width: 300, decorationsRadius: 40, notchRadius: 24, shadow: true)
    
    var height: CGFloat
    var width: CGFloat
    var decorationsRadius: CGFloat
    var notchRadius: CGFloat
    var shadow: Bool = false
}
