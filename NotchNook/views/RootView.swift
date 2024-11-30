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
    var enableTextEditingForWindowWith: (_ id: UUID) -> ()
    var updateEditingTextStateFor: (_ id: UUID, _ isEditing: Bool) -> ()
    var canBecomeKey: Binding<Bool>?
    var showSettings: (SettingsLib.PaneIdentifier?) -> ()
    var screenSize: CGSize
    var screen: NSScreen
#if !SETAPP_BUILD
    var sparkleManager: SparkleManager
#endif
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
    var showIndicator: (Indicator?, _ onAllScreens: Bool) -> Void
        
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
    
    mutating func updateForScreen(displayKitId: UUID, screenSize: CGSize, notchSize: CGSize, notchNook: NotchNookState) {
        self.displayKitId = displayKitId
        self.screenSize = screenSize
        self.notchSize = notchSize
        self.notchNook = notchNook
    }
    
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
        NotchView(screen: screen)
            .environment(\.openSettings, showSettings)
            .environment(\.enableTextEditingForWindowWith, enableTextEditingForWindowWith)
            .environment(\.updateEditingTextStateFor, updateEditingTextStateFor)
            .environment(\.screenSize, screenSize)
#if !SETAPP_BUILD
            .environment(\.sparkleManager, sparkleManager)
#endif
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
            .environment(\.preventNextFocusFrontmostWindow, preventNextFocusFrontmostWindow)
            .environment(\.canBecomeKey, canBecomeKey ?? defaultCanBecomeKey)
            .modelContainer(sharedModelContainer)
            .environment(\.showIndicator, showIndicator)
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
    }
}
