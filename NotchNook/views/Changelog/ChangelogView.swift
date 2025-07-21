//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct ChangelogView: View {
    
    @State private var airdropPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "airdrop", withExtension: "mp4")!)
    @State private var mediaPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "media", withExtension: "mp4")!)

    @Environment(\.closeWindow) private var closeWindow
    
    var body: some View {
        VStack(spacing: 32) {
            
            // Top Header
            VStack(spacing: 0) {
                Image(.internalAppIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                
                VStack(spacing: 8) {
                    if let shortVersion = getShortVersion() {
                        (
                            Text("NotchNook ")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            +
                            Text("v\(shortVersion)")
                                .font(.title2)
                                .fontWeight(.ultraLight)
                                .italic()
                                .foregroundStyle(.primary.opacity(0.75))
                        )
                    } else {
                        Text("NotchNook")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text("A bunch of improvements and fixes!")
                        .font(.system(size: 16))
                        .fontWeight(.regular)
                }
            }
            
            VStack(spacing: 25) {
                VideoFeatureView(
                    player: mediaPlayer,
                    title: String(localized: "Universal media is back!"),
                    description: String(localized: "You can now see and control media from any app again. But now you can choose to show/control media from just Music or Spotify if you prefer."),
                    videoHeight: 90
                )
                
                VideoFeatureView(
                    player: airdropPlayer,
                    title: "Airdrop text and URL’s",
                    description: "",
                    videoHeight: 90
                )
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Other stuff:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ChangelogItem(icon: "✨", text: "Airdrop text and URL’s")
                        ChangelogItem(icon: "✨", text: "A lot of improvements for the calendar widget, including option to exclude all-day and multi-day events, open event/calendar on click, scroll behavior, and more.")
                        
                        ChangelogItem(icon: "🛠️", text: "Fix fullscreen behavior for non-notched screens and potentital issues with notes")
                    }
                }
                .frame(width: 600, alignment: .leading)
            }
            
            // Close Button
            Button {
                closeWindow()
            } label: {
                Text("Cool!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.nonShockingWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(ShrinkOnClick(minSize: 0.95))
            
        }
        .padding(.bottom, 32)
        .padding(.horizontal, 64)
        .overlay(alignment: .topLeading) {
            Image(.leftDecoration)
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 84)
                .padding(.leading, 25)
                .blendMode(.overlay)
                .opacity(0.5)
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 25) {
                Image(.rightDecoration)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 111, height: 72)
                    .padding(.top, 4)
                    .padding(.trailing, 25)
                    .blendMode(.overlay)
                    .opacity(0.5)
                
                Image(.loriSignature)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 111, height: 72)
                    .padding(.trailing, 25)
                    .blendMode(.overlay)
                    .opacity(0.5)
                    .rotationEffect(.degrees(22))
            }
        }
        .background {
            Image(.changelogGradient)
                .resizable()
                .scaledToFill()
                .opacity(0.4)
                .ignoresSafeArea()
        }
        .background {
            VisualEffectViews(material: .popover)
                .ignoresSafeArea()
        }
    }
}

struct ChangelogItem: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.system(size: 18))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 14))
                .fontWeight(.regular)
        }
    }
}
