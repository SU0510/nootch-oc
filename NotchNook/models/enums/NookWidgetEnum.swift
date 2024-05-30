//
//  NookWidget.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

enum NookWidget: String, MetaInfo, Codable, CaseIterable {
    case media, shortcuts, mirror
    
    var id: String { self.rawValue }
    
    var description: String? {
        return switch self.gridSizeType {
        case .unique(let size): "\(size.width.value) cells"
        default: "\(self.prefs.size.width.value) cells"
        }
    }
    
    var icon: String {
        return switch self {
        case .media: "music.note"
        case .shortcuts: "sparkles"
        case .mirror: "web.camera.fill"
        }
    }
    
    var name: String {
        return switch self {
        case .media: "Media Player"
        case .shortcuts: "Shortcuts"
        case .mirror: "Mirror"
        }
    }
    
    var prefs: any WidgetPrefs {
        return switch self {
        case .media: Defaults[.mediaWidgetSettings]
        case .shortcuts: Defaults[.shortcutsWidgetSettings]
        case .mirror: Defaults[.mirrorWidgetSettings]
        }
    }
    
    var gridSizeType: GridSizeType {
        return switch self {
        case .media: .unique(.init(width: MediaWidgetSettings().size.width, height: MediaWidgetSettings().size.height))
        case .shortcuts: .variable
        case .mirror: .unique(.init(width: MirrorWidgetSettings().size.width, height: MirrorWidgetSettings().size.height))
        }
    }
    
    enum GridSizeType {
        case unique(Grid.Size), multiple([Grid.Size]), variable
    }
}
