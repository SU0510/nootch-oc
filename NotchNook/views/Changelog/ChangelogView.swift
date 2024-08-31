//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct ChangelogView: View {
    @State private var globalMediaPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "global-media", withExtension: "mov")!)
    @State private var indicatorsPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "indicators", withExtension: "mov")!)
    @State private var lockPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "lock", withExtension: "mov")!)
    @Environment(\.closeWindow) private var closeWindow
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 0) {
                Image(.internalAppIcon).resizable()
                    .scaledToFit()
                    .frame(128)
                VStack(spacing: 8) {
                    VStack(spacing: 0) {
                        if let shortVersion = getShortVersion() {
                            Text("NotchNook ").font(.largeTitle).fontWeight(.bold) +
                            Text("v\(shortVersion)").font(.title2).fontWeight(.ultraLight).italic().foregroundStyle(.primary.opacity(0.75))
                        } else {
                            Text("NotchNook ").font(.largeTitle).fontWeight(.bold)
                        }
                    }
                    Text("Natural animations and fresh new features!").font(.system(size: 16)).fontWeight(.regular)
                }
            }
            VStack(spacing: 16) {
                VideoFeatureView(player: globalMediaPlayer, title: String(localized: "Global Media Controlling"), description: String(localized: "Now you can control any media from any app!"))
                VideoFeatureView(player: indicatorsPlayer, title: String(localized: "Brightness/Volume HUD Replacement"), description: String(localized: "Now you can replace the default volume and brightness indicators by custom ones in \"Live Activities\" settings!"))
                VideoFeatureView(player: lockPlayer, title: String(localized: "Lock Button"), description: String(localized: "Prevent NN from auto-closing with the new lock button."))
            }
            
            Button {
                closeWindow()
            } label: {
                Text("Holy cow, amazing!")
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
            Image(.leftDecoration).resizable().scaledToFit()
                .frame(width: 123, height: 84)
                .padding(.leading, 25)
                .blendMode(.overlay)
                .opacity(0.5)
        }
        .overlay(alignment: .topTrailing) {
            Image(.rightDecoration).resizable().scaledToFit()
                .frame(width: 111, height: 72)
                .padding(.top, 4)
                .padding(.trailing, 25)
                .blendMode(.overlay)
                .opacity(0.5)
        }
        .background {
            Image(.changelogGradient).resizable()
                .scaledToFill()
                .opacity(0.4)
                .ignoresSafeArea(.all)
        }
        .background {
            VisualEffectViews(material: .popover)
                .ignoresSafeArea(.all)
        }
    }
}
