//
//  AboutSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Settings
import Sparkle

struct AboutSettingsView: View {
    @ObservedObject var checkForUpdatesViewModel: CheckForUpdatesViewModel
    let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(.internalAppIcon).resizable()
                    .frame(96)
                
                VStack(alignment: .leading) {
                    Text("NotchNook").font(.title).fontWeight(.bold)
                    Text(getAppVersion()).font(.callout)
                }
                Spacer()
                Button("Check for Updates…", action: updater.checkForUpdates)
                .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
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
                            Label("lo.cafe website", systemImage: "globe")
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
                    }
                }
                .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("A few of our apps")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(rowlify(elements: globalAppsRecommentations).enumerated()), id: \.offset) { _, row in
                            HStack(spacing: 8) {
                                ForEach(row) { app in
                                    AppRecommendationView(app: app)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .defaultSettingsProps(height: 600)
    }
}

let AboutSettingsViewController: (_ updater: SPUUpdater) -> SettingsPane = { updater in
    let paneView = Settings.Pane(
        identifier: .about,
        title: "About",
        toolbarIcon: NSImage(systemSymbolName: "ellipsis.circle.fill", accessibilityDescription: "About settings")!
    ) {
        AboutSettingsView(updater: updater)
    }

    return Settings.PaneHostingController(pane: paneView)
}

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
