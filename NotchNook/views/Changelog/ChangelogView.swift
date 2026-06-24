//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI
import AVKit

struct ChangelogView: View {

    @Environment(\.closeWindow) private var closeWindow

    // Looping players for the featured-widget videos. Built once; degrade
    // gracefully to a text-only highlight if a video is missing from the bundle.
    @State private var timerPlayer: AVLooperPlayer? = ChangelogView.looper("timer")
    @State private var todoPlayer: AVLooperPlayer? = ChangelogView.looper("to-do")

    private static func looper(_ name: String) -> AVLooperPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return nil }
        return AVLooperPlayer(url: url)
    }

    // Cap the scroll area (and therefore the window) below the screen height so
    // it never runs edge to edge.
    private var maxContentHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        return screenHeight - 120
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
        }
        .frame(width: 728, height: maxContentHeight)
        .background {
            decorations
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

    /// Background decorations — pinned to the window (outside the scroll area) and
    /// nudged down from the very top so they don't crowd the header.
    private var decorations: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top) {
                Image(.leftDecoration)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 123, height: 84)
                    .padding(.leading, 25)
                    .blendMode(.overlay)
                    .opacity(0.5)

                Spacer()

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
            .padding(.top, 90)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var content: some View {
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

            VStack(alignment: .leading, spacing: 24) {

                // Featured widgets (with looping videos)
                VStack(alignment: .leading, spacing: 20) {
                    if let timerPlayer {
                        VideoFeatureView(
                            player: timerPlayer,
                            title: String(localized: "New Timer widget"),
                            description: String(localized: "Scrollable wheels with haptic feedback and a Liquid Glass focus pill, calendar-style scroll glue, and progressive blur.")
                        )
                    }

                    if let todoPlayer {
                        VideoFeatureView(
                            player: todoPlayer,
                            title: String(localized: "New To-do list widget"),
                            description: String(localized: "A quick task list with favorites, completion, and auto-archiving.")
                        )
                    }
                }

                // New
                VStack(alignment: .leading, spacing: 16) {
                    Text("Also new:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ChangelogItem(icon: "🎵", text: String(localized: "Media: pick which Now Playing source to show, plus a draggable progress scrubber."))
                        ChangelogItem(icon: "🔋", text: String(localized: "New Battery live activity — plugged, unplugged, full, and low-battery transitions."))
                        ChangelogItem(icon: "🔵", text: String(localized: "New Bluetooth live activity — device connect and disconnect."))
                        ChangelogItem(icon: "👁️", text: String(localized: "Per-activity visibility control in fullscreen."))
                        ChangelogItem(icon: "🗂️", text: String(localized: "Smarter Tray: stack multiple dropped files at once, persistence across restarts, paste from clipboard, and Option-drag to move."))
                    }
                }

                // Fixes & improvements
                VStack(alignment: .leading, spacing: 16) {
                    Text("Fixes & improvements:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ChangelogItem(icon: "🛠️", text: String(localized: "Settings window is now resizable, self-recovers from a corrupted size, and the tabs scroll properly."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Notch overhaul: first-click absorption, cursor tracking, keyboard focus, and text editing all fixed."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Media: progress advances live, livelier circle/waves effects, and Now Playing detection restored."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Battery no longer fires a quick peek on every 1% change."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "To-do: right-click delete no longer closes the Nook, plus input focus fixes."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Calendar: event sync, overnight-event filtering, and end-of-event live activity dismiss."))
                        ChangelogItem(icon: "🛠️", text: String(localized: "Notes: data-loss prevention and an observer leak fix."))
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
        .padding(.top, 32)
        .padding(.bottom, 32)
        .padding(.horizontal, 64)
        .frame(maxWidth: .infinity)
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
