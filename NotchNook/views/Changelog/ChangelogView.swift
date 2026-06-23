//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct ChangelogView: View {

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

                    Text("Timers, todos, and a lot more.")
                        .font(.system(size: 16))
                        .fontWeight(.regular)
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ChangelogItem(icon: "⏱️", text: String(localized: "New Timer widget — scrollable wheels with a Liquid Glass focus pill and haptics."))
                        ChangelogItem(icon: "✅", text: String(localized: "New Todo list widget — quick tasks with priority, completion, and auto-archiving."))
                        ChangelogItem(icon: "🎵", text: String(localized: "Media: pick which app to show/control, plus a draggable progress bar."))
                        ChangelogItem(icon: "🔋", text: String(localized: "New Battery and Bluetooth live activities."))
                        ChangelogItem(icon: "🗂️", text: String(localized: "Smarter Tray: multi-file stacking, persistence across restarts, paste from clipboard, and Option-drag to move."))
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Fixes & improvements:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ChangelogItem(icon: "🛠️", text: String(localized: "The Settings window is now resizable."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Notch typing and focus overhaul — no more swallowed first click."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Media progress now advances live, with livelier effects and universal media restored."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Calendar and notes reliability fixes."))
                    }
                }
            }
            .frame(width: 600, alignment: .leading)

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
