//
//  LiveActivity.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

enum LiveActivity: String, Codable, MetaInfo, CaseIterable {
    
    case media
    case tray
    case calendar
    case updateAvailable
    case bluetoothDevice
    case batteryVisualizer
    
    var id: String { self.rawValue }
    
    var description: String? { nil }
    
    var isImplemented: Bool {
        switch self {
            case .batteryVisualizer:
                false
            default:
                true
        }
    }
    
    var icon: String {
        return switch self {
            case .media: "music.note"
            case .tray: "tray.fill"
            case .calendar: "calendar.badge.clock.rtl"
            case .updateAvailable: "arrow.down.circle"
            case .bluetoothDevice: "airpods"
            case .batteryVisualizer: "bolt.fill"
        }
    }
    
    var name: String {
        return switch self {
            case .media: String(localized: "Media")
            case .tray: String(localized: "Files Tray")
            case .calendar: String(localized: "Calendar")
            case .updateAvailable: String(localized: "New Update")
            case .bluetoothDevice: String(localized: "Bluetooth")
            case .batteryVisualizer: String(localized: "Battery")
        }
    }
}
