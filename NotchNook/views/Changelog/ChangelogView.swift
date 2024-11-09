//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct ChangelogView: View {
    
    @State private var notesPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "notes-widget", withExtension: "mov")!)
    @State private var fullscreenPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "fullscreen", withExtension: "mov")!)
    @State private var fineTuningPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "fine-tuning-height", withExtension: "mp4")!)

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
                    Text("Fresh new features and a bunch of fixes!").font(.system(size: 16)).fontWeight(.regular)
                }
            }
            
            VStack(spacing: 16) {
                VideoFeatureView(
                    player: notesPlayer,
                    title: String(localized: "Notes widget"),
                    description: String(localized: "Now you can write down quick thoughts and even code in NotchNook!")
                )
                
                VideoFeatureView(
                    player: fullscreenPlayer,
                    title: String(localized: "Show in fullscreen option"),
                    description: String(localized: "Now you decide whether to show NotchNook in fullscreen mode or not!")
                )
                
                VideoFeatureView(
                    player: fineTuningPlayer,
                    title: String(localized: "Notch height fine tune"),
                    description: String(localized: "If the height is a bit off of your built-in notch, you can adjust it now!")
                )
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
            VStack(spacing: 25) {
                Image(.rightDecoration).resizable().scaledToFit()
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
