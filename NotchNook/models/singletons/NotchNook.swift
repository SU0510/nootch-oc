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
    
    var quickPeaks: [QuickPeak]? {
        get { _quickPeak }
        set {
            vibrate()
            withAnimation(TopBarView.animation) { _quickPeak = newValue }
        }
    }
    private var _quickPeak: [QuickPeak]?
    
    var activeLiveActivities: Set<LiveActivity> {
        get { Defaults[.liveActivitiesSettings].enabled ? _activeLiveActivities : [] }
        set { withAnimation(TopBarView.animation) { _activeLiveActivities = newValue } }
    }
    private var _activeLiveActivities = Set<LiveActivity>()
    
    var mode = [UUID:NotchMode]()
    
    enum NotchMode: String, Hashable {
        case closed, nook, shelf, dragging
    }
    
    struct QuickPeak: Identifiable, Equatable, Hashable {
        let id = UUID()
        let icon: String?
        let text: String
        var iconColor: Color? = nil
    }
}
