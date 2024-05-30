//
//  defaults.swift
//  NotchNook
//
//  Created by Ethan Bills on 5/23/24.
//

import SwiftUI
import Defaults

// Define the defaults keys
extension Defaults.Keys {
    static let email = Key<String>("email", default: "")
    static let licenseKey = Key<String>("licenseKey", default: "")
    static let keyActive = Key<Bool>("keyActive", default: false)
    
    static let mediaLiveActivitySettings = Key<MediaLiveActivitySettings>("mediaLiveActivitySettings", default: .init())
    static let liveActivitiesSettings = Key<LiveActivitiesSettings>("liveActivitiesSettings", default: .init())
    static let generalSettings = Key<GeneralSettings>("generalSettings", default: .init())
    static let mediaWidgetSettings = Key<MediaWidgetSettings>("mediaWidgetSettings", default: .init())
    static let shortcutsWidgetSettings = Key<ShortcutsWidgetSettings>("shortcutsWidgetSettings", default: .init())
    static let mirrorWidgetSettings = Key<MirrorWidgetSettings>("mirrorWidgetSettings", default: .init())
    static let gestureControlSettings = Key<GestureControlSettings>("gestureControlSettings", default: .init())
    static let nookSettings = Key<NookSettings>("nookSettings", default: .init())
    static let shelfSettings = Key<ShelfSettings>("shelfSettings", default: .init())
    static let dropAreaSettings = Key<DropAreaSettings>("dropAreaSettings", default: .init())
}
