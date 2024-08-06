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
class NotchNookState {
    
    var hidden: Bool = false {
        willSet {
            if !hidden && newValue { vibrate() }
            if !newValue { hiddenTimer?.invalidate() }
        }
        didSet {
            if hidden && Defaults[.liveActivitiesSettings].unhideAutomatically {
                hiddenTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                    withAnimation(.smooth) { self.hidden = false }
                }
            }
        }
    }
    var hiddenTimer: Timer?
    
    var indicator: Indicator? {
        willSet { indicatorTimer?.invalidate() }
        didSet {
            if indicator != nil {
                indicatorTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    withAnimation(.smooth) { self.indicator = nil }
                }
            }
        }
    }
    var indicatorTimer: Timer?
    
    var locked = false
    
    var quickPeeks: [QuickPeek]? {
        get { _quickPeek }
        set {
            if let newValue, !newValue.isEmpty { vibrate() }
            withAnimation(TopBarView.animation) { _quickPeek = newValue }
        }
    }
    private var _quickPeek: [QuickPeek]?
    
    var mode: NotchMode = .closed
    
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

