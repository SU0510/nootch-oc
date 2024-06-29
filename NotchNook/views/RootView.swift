//
//  RootView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import SwiftData

struct RootView: View {
    var canBecomeKey: Binding<Bool>?
    var showSettings: (SettingsLib.PaneIdentifier?) -> ()
    var screenSize: CGSize
    var sparkleManager: SparkleManager
    var showChangelog: () -> ()
    var notchSize: CGSize
    var notchNook: NotchNook
    var focusFrontmostWindow: () -> ()
    var makeKeyWindow: (() -> ())?
    var resignFirstResponder: () -> ()
    var preventNextFocusFrontmostWindow: () -> ()
    var isEditingText: Bool
    var isKeyWindow: Bool
    @Environment(\.makeKeyWindow) private var defaultBecomeKeyWindow
    @Environment(\.canBecomeKey) private var defaultCanBecomeKey
    
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
            .environment(\.isKeyWindow, isKeyWindow)
            .environment(\.canBecomeKey, canBecomeKey ?? defaultCanBecomeKey)
            .modelContainer(sharedModelContainer)
    }
}
