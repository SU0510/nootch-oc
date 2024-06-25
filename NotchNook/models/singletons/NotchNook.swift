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
    
    var tray = Tray()
    var pinned = false
    
    var quickPeeks: [QuickPeek]? {
        get { _quickPeek }
        set {
            vibrate()
            withAnimation(TopBarView.animation) { _quickPeek = newValue }
        }
    }
    private var _quickPeek: [QuickPeek]?
    
    var activeLiveActivities: Set<LiveActivity> {
        get { Defaults[.liveActivitiesSettings].enabled ? _activeLiveActivities : [] }
        set { withAnimation(TopBarView.animation) { _activeLiveActivities = newValue } }
    }
    private var _activeLiveActivities = Set<LiveActivity>()
    
    var mode = [UUID:NotchMode]()
    
    enum NotchMode: String, Hashable {
        case closed, nook, tray, dragging
    }
    
    struct QuickPeek: Identifiable, Equatable, Hashable {
        let id = UUID()
        let icon: String?
        let text: String
        var iconColor: Color? = nil
    }
}
