//
//  NookWidget.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

enum NookWidget: String, MetaInfo, Codable, CaseIterable {
    case shortcuts, media, mirror, calendar, notes, quickApps
    
    var id: String { self.rawValue }
    
    var description: String? {
        return switch self.gridSizeType {
        case .unique(let size): "\(size.width.value) cells"
        default: "\(self.prefs.size.width.value) cells"
        }
    }
    
    var isImplemented: Bool {
        return switch self {
        case .media, .shortcuts, .mirror, .calendar: true
        case .notes, .quickApps: false
        }
    }
    
    var icon: String {
        return switch self {
        case .media: "music.note"
        case .shortcuts: "sparkles"
        case .mirror: "web.camera.fill"
        case .calendar: "calendar"
        case .notes: "note.text"
        case .quickApps: "circle.grid.2x2.fill"
        }
    }
    
    var name: String {
        return switch self {
        case .media: "Media Player"
        case .shortcuts: "Shortcuts"
        case .mirror: "Mirror"
        case .calendar: "Calendar"
        case .notes: "Notes"
        case .quickApps: "Quick Apps"
        }
    }
    
    var prefs: any WidgetPrefs {
        return switch self {
        case .calendar: Defaults[.calendarWidgetSettings]
        case .media: Defaults[.mediaWidgetSettings]
        case .shortcuts: Defaults[.shortcutsWidgetSettings]
        case .mirror: Defaults[.mirrorWidgetSettings]
        case .notes: Defaults[.mirrorWidgetSettings]
        case .quickApps: Defaults[.mirrorWidgetSettings]
        }
    }
    
    var gridSizeType: NookGridSizeType {
        return switch self {
        case .calendar: .variable
        case .media: .unique(.init(width: MediaWidgetSettings().size.width, height: MediaWidgetSettings().size.height))
        case .shortcuts: .variable
        case .mirror: .unique(.init(width: MirrorWidgetSettings().size.width, height: MirrorWidgetSettings().size.height))
        case .notes: .unique(.init(width: MirrorWidgetSettings().size.width, height: MirrorWidgetSettings().size.height))
        case .quickApps: .unique(.init(width: MirrorWidgetSettings().size.width, height: MirrorWidgetSettings().size.height))
        }
    }
    
    enum NookGridSizeType {
        case unique(NookGrid.Size), multiple([NookGrid.Size]), variable
    }
}
