//
//  NoMediaAppsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct NoMediaAppsView: View {
    @State private var installedApps = [SystemAppMeta]()
    
    @Environment(\.preventNextFocusFrontmostWindow) private var preventNextFocusFrontmostWindow
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack {
            Text("No app seems to be running")
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 11, weight: .medium)).opacity(0.75)
            Text("Wanna open one?").font(.system(size: 13, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 8) {
                ForEach(installedApps.sorted().prefix(3)) { mediaAppMeta in
                    Button {
                        MediaManager.shared.forceMediaControllerRestart(appName: mediaAppMeta.name)
                        preventNextFocusFrontmostWindow()
                        mediaAppMeta.openApp()
                    } label: {
                        Image(nsImage: mediaAppMeta.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(38)
                    }
                }
                
                Button {
                    MediaManager.shared.reconfigureMediaController()
                    
                    guard let youtubeURL = URL(string: "https://www.youtube.com/") else { return }
                    preventNextFocusFrontmostWindow()
                    openURL(youtubeURL)
                } label: {
                    Image(.youtubeLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(31)
                        .frame(38)
                }
            }
            .buttonStyle(ShrinkOnClick())
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.nonShockingWhite)
        .transition(.scaleAndBlur(anchor: .topTrailing))
        .onAppear {
            installedApps = getInstalledMediaApps()
        }
    }
    
    func getInstalledMediaApps() -> [SystemAppMeta] {
        let mediaBundleIDs = [
            "com.spotify.client",
            "com.apple.Music",
            "com.spotube.SpotubeMacOS",
            "sh.cider.Cider",
            "com.tidal.desktop",
            "com.coppertino.Vox",
            "com.tencent.QQMusicMac",
            "com.netease.163music",
            "com.kugou.player",
            "com.deezer.DeezerDesktop"
        ]
        
        func isAppInstalled(_ bundleID: String) -> Bool {
            let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
            return appURL != nil
        }
        
        return mediaBundleIDs.compactMap {
            isAppInstalled($0) ? SystemAppMeta(bundleId: $0) : nil
        }
    }

}
