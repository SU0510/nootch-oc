//
//  LiveActivity.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

enum LiveActivity: String, Codable, MetaInfo, CaseIterable {
    case media, shelf, calendar
    
    var id: String { self.rawValue }
    
    var description: String? { nil }
    
    var isImplemented: Bool {
        return switch self {
        case .shelf, .media: true
        case .calendar: false
        }
    }
    
    var icon: String {
        return switch self {
        case .media: "music.note"
        case .shelf: "tray.fill"
        case .calendar: "calendar"
        }
    }
    
    var name: String {
        return switch self {
        case .media: "Media"
        case .shelf: "Files Tray"
        case .calendar: "Calendar"
        }
    }
}
