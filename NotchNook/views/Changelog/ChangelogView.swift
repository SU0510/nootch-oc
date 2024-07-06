//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct ChangelogView: View {
    @State private var calendarPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "calendar", withExtension: "mov")!)
    @State private var calendarLAPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "calendarLA", withExtension: "mov")!)
    @State private var quickPeekPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "quickPeek", withExtension: "mov")!)
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
                    Text("A bunch of bug fixes and sweet new features!").font(.system(size: 16)).fontWeight(.regular)
                }
            }
            VStack(spacing: 16) {
                VideoFeatureView(player: calendarPlayer, title: String(localized: "Calendar Widget"), description: String(localized: "Check your upcoming events in a lickable interface and fantastic haptics. Event editing and more will be coming soon..."))
                VideoFeatureView(player: quickPeekPlayer, title: String(localized: "Quick Peek"), description: String(localized: "Take a quick peek at useful info by hovering some of the live activities."))
                VideoFeatureView(player: calendarLAPlayer, title: String(localized: "Calendar Live Activity"), description: String(localized: "A new elegant way of getting notified about and joining a meeting. "))
            }
            
            Button {
                closeWindow()
            } label: {
                Text("Damn, that's awesome!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
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
