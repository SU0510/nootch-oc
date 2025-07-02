//
//  NoMediaAppsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct NoMediaAppsView: View {
    
    @State private var installedApps = [SystemAppMeta]()
    @State private var spotifyIsInstalled = false
    
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
            let spotifyBundleID = "com.spotify.client"
            let appleBundleID = "com.apple.Music"
            let spotubeBundleID = "com.spotube.SpotubeMacOS"
            let ciderBundleID = "sh.cider.Cider"
            let tidalBundleID = "com.tidal.desktop"
            let voxBundleID = "com.coppertino.Vox"
            let qqMusicBundleID = "com.tencent.QQMusicMac"
            let netEaseCloudMusicBundleID = "com.netease.163music"
            let kuGouMusicBundleID = "com.kugou.player"
            
            let appsBundleIds = [spotifyBundleID, appleBundleID, spotubeBundleID, ciderBundleID, tidalBundleID, voxBundleID]
            installedApps = appsBundleIds.compactMap { isAppInstalled($0) ? SystemAppMeta(bundleId: $0) : nil }
        }
    }
}

