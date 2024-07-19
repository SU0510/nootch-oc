//
//  RootView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import SwiftData
import Defaults

struct RootView: View {
    var displayKitId: UUID
    var canBecomeKey: Binding<Bool>?
    var showSettings: (SettingsLib.PaneIdentifier?) -> ()
    var screenSize: CGSize
    var sparkleManager: SparkleManager
    var showChangelog: () -> ()
    var notchSize: CGSize
    var notchNook: NotchNookState
    var focusFrontmostWindow: () -> ()
    var makeKeyWindow: (() -> ())?
    var resignFirstResponder: () -> ()
    var preventNextFocusFrontmostWindow: () -> ()
    var isEditingText: Bool
    var isKeyWindow: Bool
    var expandedNoteManager: ExpandedNoteManager
    @Environment(\.makeKeyWindow) private var defaultBecomeKeyWindow
    @Environment(\.canBecomeKey) private var defaultCanBecomeKey
    @Default(.generalSettings) private var generalSettings
    @Default(.gestureControlSettings) private var gestureControlSettings
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.nookSettings) private var nookSettings
    @Default(.traySettings) private var traySettings
    @Default(.dropAreaSettings) private var dropAreaSettings
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    @Default(.mediaWidgetSettings) private var mediaWidgetSettings
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.mirrorWidgetSettings) private var mirrorWidgetSettings
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @Default(.notesWidgetSettings) private var notesWidgetSettings
    @Default(.todoListWidgetSettings) private var todoListWidgetSettings
    @Default(.quickAppsWidgetSettings) private var quickAppsWidgetSettings
    
    var sharedModelContainer: ModelContainer = {
        NSAttributedStringTransformer.register()
        
        let schema = Schema([
            Note.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some View {
        NotchView()
            .environment(\.openSettings, showSettings)
            .environment(\.screenSize, screenSize)
            .environment(\.sparkleManager, sparkleManager)
            .environment(\.showChangelog, showChangelog)
            .environment(\.notchSize, notchSize)
            .environment(\.notchNook, notchNook)
            .environment(\.focusFrontmostWindow, focusFrontmostWindow)
            .environment(\.makeKeyWindow, makeKeyWindow ?? defaultBecomeKeyWindow)
            .environment(\.resignFirstResponder, resignFirstResponder)
            .environment(\.isEditingText, isEditingText)
            .environment(\.expandedNoteManager, expandedNoteManager)
            .environment(\.displayKitId, displayKitId)
            .environment(\.isKeyWindow, isKeyWindow)
            .environment(\.canBecomeKey, canBecomeKey ?? defaultCanBecomeKey)
            .modelContainer(sharedModelContainer)
        // Defaults
            .environment(\.generalSettings, generalSettings)
            .environment(\.gestureControlSettings, gestureControlSettings)
            .environment(\.liveActivitiesSettings, liveActivitiesSettings)
            .environment(\.nookSettings, nookSettings)
            .environment(\.traySettings, traySettings)
            .environment(\.dropAreaSettings, dropAreaSettings)
            .environment(\.mediaLiveActivitySettings, mediaLiveActivitySettings)
            .environment(\.calendarLiveActivitySettings, calendarLiveActivitySettings)
            .environment(\.mediaWidgetSettings, mediaWidgetSettings)
            .environment(\.shortcutsWidgetSettings, shortcutsWidgetSettings)
            .environment(\.mirrorWidgetSettings, mirrorWidgetSettings)
            .environment(\.calendarWidgetSettings, calendarWidgetSettings)
            .environment(\.notesWidgetSettings, notesWidgetSettings)
            .environment(\.todoListWidgetSettings, todoListWidgetSettings)
            .environment(\.quickAppsWidgetSettings, quickAppsWidgetSettings)
            .environment(\.generalSettings, generalSettings)
            .environment(\.gestureControlSettings, gestureControlSettings)
            .environment(\.liveActivitiesSettings, liveActivitiesSettings)
            .environment(\.nookSettings, nookSettings)
            .environment(\.traySettings, traySettings)
            .environment(\.dropAreaSettings, dropAreaSettings)
            .environment(\.mediaLiveActivitySettings, mediaLiveActivitySettings)
            .environment(\.calendarLiveActivitySettings, calendarLiveActivitySettings)
            .environment(\.mediaWidgetSettings, mediaWidgetSettings)
            .environment(\.shortcutsWidgetSettings, shortcutsWidgetSettings)
            .environment(\.mirrorWidgetSettings, mirrorWidgetSettings)
    }
}
