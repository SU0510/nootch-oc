//
//  AboutSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Settings
#if !SETAPP_BUILD
import Sparkle
#endif
import Defaults

struct AboutSettingsView: View {
#if !SETAPP_BUILD
    @State private var sparkleManager: SparkleManager
#endif
    @Environment(\.showChangelog) private var showChangelog
#if !SETAPP_BUILD
    init(sparkleManager: SparkleManager) {
        self._sparkleManager = .init(initialValue: sparkleManager)
    }
#endif
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(.internalAppIcon).resizable()
                    .frame(96)
                
                VStack(spacing: 3) {
                    HStack(alignment: .bottom) {
                        Text("NotchNook").font(.title).fontWeight(.bold)
                        Spacer()
#if !SETAPP_BUILD
                        Button("Check for Updates…", action: sparkleManager.checkForUpdates)
                            .disabled(!sparkleManager.canCheckForUpdates)
                            .padding(.bottom, 3)
#endif
                    }
                    
                    HStack(alignment: .top) {
                        (Text("v\(getAppVersion()) ").font(.callout) + Text("(see changelog)").font(.caption).underline().foregroundStyle(.primary.opacity(0.5)))
                            .opacity(0.75)
                            .onTapGesture(perform: showChangelog)
                        Spacer()
#if !SETAPP_BUILD
                        HStack {
                            if sparkleManager.automaticallyChecksForUpdates {
                                Toggle("Auto download updates", isOn: $sparkleManager.automaticallyDownloadsUpdates)
                            }
                            Toggle("Auto check for updates", isOn: $sparkleManager.automaticallyChecksForUpdates)
                                .onChange(of: sparkleManager.automaticallyChecksForUpdates) { oldValue, newValue in
                                    if !newValue {
                                        sparkleManager.automaticallyDownloadsUpdates = false
                                        Defaults[.liveActivitiesSettings].enabledLiveActivities.remove(.updateAvailable)
                                    } else {
                                        Defaults[.liveActivitiesSettings].enabledLiveActivities.insert(.updateAvailable)
                                    }
                                }
                        }
#endif
                    }
                    
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("NotchNook is made by").fontWeight(.medium).opacity(0.25)
                    LoCafeLogoView()
                    Text("A group of talented friends from 4 different countries that develop amazing software together for nothing but passion.")
                        .opacity(0.75)
                        .padding(.horizontal, 48)
                }
                .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text("Some links:")
                        .fontWeight(.medium)
                        .opacity(0.75)
                        .padding(.horizontal, 48)
                    
                    HStack {
                        SettingsLinkBtn(url: URL(string: "https://lo.cafe")) {
                            Label("lo.cafe site", systemImage: "globe")
                        }
                        SettingsLinkBtn(url: URL(string: "https://discord.gg/lo-cafe")) {
                            Label {
                                Text("Discord server")
                            } icon: {
                                Image(.discordLogo).resizable().scaledToFit().frame(14)
                            }
                        }
                        SettingsLinkBtn(url: URL(string: "mailto:hi@lo.cafe")) {
                            Label("Email us!", systemImage: "at")
                        }
                        SettingsLinkBtn(url: URL(string: "https://lo.cafe/notchnook/privacy-policy")) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                        }
                    }
                }
                .multilineTextAlignment(.center)
                
//                VStack(spacing: 16) {
//                    Text("A few of our apps")
//                        .fontWeight(.semibold)
//                        .font(.title2)
//                        .multilineTextAlignment(.center)
//                    
//                    VStack(spacing: 8) {
//                        ForEach(Array(rowlify(elements: globalAppsRecommentations).enumerated()), id: \.offset) { _, row in
//                            HStack(spacing: 8) {
//                                ForEach(row) { app in
//                                    AppRecommendationView(app: app)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                }
//                            }
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                }
            }
        }
        .padding(16)
        .defaultSettingsProps(height: nil)
    }
}

#if !SETAPP_BUILD
let AboutSettingsViewController: (
    _ sparkleManager: SparkleManager,
    _ showChangelog: (() -> ())?
) -> SettingsPane = { sparkleManager, showChangelog in
    let paneView = Settings.Pane(
        identifier: .about,
        title: String(localized: "About"),
        toolbarIcon: NSImage(systemSymbolName: "ellipsis.circle.fill", accessibilityDescription: "About settings")!
    ) {
        AboutSettingsView(sparkleManager: sparkleManager)
            .environment(\.sparkleManager, sparkleManager)
            .environment(\.showChangelog, showChangelog ?? {})
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
#else 
let AboutSettingsViewController: (
    _ showChangelog: (() -> ())?
) -> SettingsPane = { showChangelog in
    let paneView = Settings.Pane(
        identifier: .about,
        title: String(localized: "About"),
        toolbarIcon: NSImage(systemSymbolName: "ellipsis.circle.fill", accessibilityDescription: "About settings")!
    ) {
        AboutSettingsView()
            .environment(\.showChangelog, showChangelog ?? {})
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
#endif

private struct AppRecommendationView: View {
    var app: AppRecommendation
    @Environment(\.openURL) private var openURL
    @State private var hovering = false
    
    var body: some View {
        SettingsLinkBtn(url: app.url, inline: false) {
            HStack {
                Image(app.image).resizable().scaledToFit().frame(56).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(app.title).fontWeight(.medium).opacity(0.95)
                    Text(app.description).font(.system(size: 12)).opacity(0.75)
                }
            }
        }
    }
}
