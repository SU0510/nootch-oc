//
//  NotchNook.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import SwiftUI
import Defaults

@Observable
class NotchNook {
    static let shared = NotchNook()
    
    var shelf = Shelf()
    var pinned = false
    var activeLiveActivities: Set<LiveActivity> {
        get {
            return Defaults[.liveActivitiesSettings].enabled ? _activeLiveActivities : []
        }
        set {
            _activeLiveActivities = newValue
        }
    }
    private var _activeLiveActivities = Set<LiveActivity>()
    var mode = [UUID:NotchMode]()
    
    enum NotchMode: String, Hashable {
        case closed, nook, shelf, dragging
    }
}

