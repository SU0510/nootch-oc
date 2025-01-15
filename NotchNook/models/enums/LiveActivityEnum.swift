//
//  LiveActivity.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

enum LiveActivity: String, Codable, MetaInfo, CaseIterable {
    case media, tray, calendar, updateAvailable, batteryVisualizer
    
    var id: String { self.rawValue }
    
    var description: String? { nil }
    
    var isImplemented: Bool {
        return switch self {
            default: true
        }
    }
    
    var icon: String {
        return switch self {
            case .media: "music.note"
            case .tray: "tray.fill"
            case .calendar: "calendar.badge.clock.rtl"
            case .updateAvailable: "arrow.down.circle"
            case .batteryVisualizer: "battery.100percent.circle"
        }
    }
    
    var name: String {
        return switch self {
            case .media: String(localized: "Media")
            case .tray: String(localized: "Files Tray")
            case .calendar: String(localized: "Calendar")
            case .updateAvailable: String(localized: "New Update")
            case .batteryVisualizer: String(localized: "Battery")
        }
    }
}
