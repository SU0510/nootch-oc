//
//  MediaPlayerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct MediaPlayerView: View, Equatable {
    static func == (lhs: MediaPlayerView, rhs: MediaPlayerView) -> Bool {
        lhs.track == rhs.track
    }
    
    var track: Track
    @Environment(\.namespace) private var ns

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    MediaManager.shared.openApp()
                } label: {
                    AlbumCoverView(id: track.albumId, artwork: track.albumArt, cornerRadius: 28)
                        .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                        .overlay(alignment: .bottomTrailing) {
                            if track.mediaApp.icon.isValid {
                                Image(nsImage: track.mediaApp.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .shadow(color: .black.opacity(0.33), radius: 8, y: 0)
                                    .shadow(color: .black.opacity(1), radius: 12, y: 3)
                                    .frame(32)
                                    .offset(x: 6, y: 6)
                            }
                        }
                }
                .buttonStyle(ShrinkOnClick())

                VStack(alignment: .leading, spacing: 2) {
                    VStack(alignment: .leading, spacing: 2) {
                        Group {
                            Text(track.title)
                                .id(track.title)
                                .font(.system(size: 14, weight: .semibold))
                                .truncationMode(.tail)
                                .lineLimit(2)
                                .truncationMode(.tail)

                            if !track.album.isEmpty {
                                Text(track.album)
                                    .id(track.album)
                                    .lineLimit(1)
                                    .font(.system(size: 12, weight: .semibold))
                                    .opacity(0.65)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                            }

                            if !track.artist.isEmpty {
                                Text(track.artist)
                                    .lineLimit(1)
                                    .id(track.artist)
                                    .font(.system(size: 11, weight: .medium))
                                    .opacity(0.5)
                            }
                        }
                        .transition(.scaleAndBlur)
                    }
                    .allowsHitTesting(false)

                    MediaControlsView()
                        .offset(x: -4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // ── Source switcher: visible only when 2+ clients are registered ──
            NowPlayingSourceSwitcherView()

            // ── Scrubber: visible only when duration is known ──
            MediaScrubberView()
        }
        .animation(.bouncySmooth, value: track.id)
        .foregroundStyle(.nonShockingWhite)
    }
}

// MARK: - Source switcher

fileprivate struct NowPlayingSourceSwitcherView: View {
    private var manager = MediaManager.shared

    var body: some View {
        let sources = manager.nowPlayingSources
        if sources.count > 1 {
            HStack(spacing: 6) {
                ForEach(sources) { source in
                    SourceChipView(source: source,
                                   isActive: manager.activeSource?.bundleIdentifier == source.bundleIdentifier,
                                   isPinned: manager.userPinnedClientID == source.bundleIdentifier)
                }
            }
            .transition(.scaleAndBlur)
        }
    }
}

fileprivate struct SourceChipView: View {
    let source: NowPlayingSource
    let isActive: Bool
    let isPinned: Bool
    @State private var hovering = false
    fileprivate var manager = MediaManager.shared

    var body: some View {
        Button {
            if isPinned {
                manager.unpinSource()
            } else {
                manager.pinSource(source)
            }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: source.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .opacity(isActive ? 1 : 0.45)

                if isPinned {
                    Circle()
                        .fill(Color.nonShockingWhite)
                        .frame(5)
                        .offset(x: 2, y: 2)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isActive ? Color.white.opacity(0.15) : Color.white.opacity(hovering ? 0.08 : 0))
            )
        }
        .buttonStyle(ShrinkOnClick())
        .help(source.displayName)
        .onHover { hovering = $0 }
    }
}

// MARK: - Scrubber

fileprivate struct MediaScrubberView: View {
    private var manager = MediaManager.shared

    /// Local position used during drag — nil when not dragging.
    @State private var dragPosition: Double? = nil

    /// Position to render: the drag value while scrubbing, otherwise the manager's
    /// extrapolated position (`currentElapsedTime` advances while playing even
    /// though MediaRemote no longer pushes periodic ticks).
    private func displayPosition() -> Double {
        dragPosition ?? max(0, manager.currentElapsedTime)
    }

    private func formatTime(_ secs: Double) -> String {
        let s = Int(max(0, secs))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    var body: some View {
        if let dur = manager.duration, dur > 0 {
            // Drive a 1 Hz refresh so the scrubber advances live while the Nook is
            // open. TimelineView only ticks while this view is on-screen, so there's
            // no cost when the widget isn't visible.
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let pos = displayPosition()
                VStack(spacing: 2) {
                    Slider(
                        value: Binding(
                            get: { pos },
                            set: { dragPosition = $0 }
                        ),
                        in: 0...dur,
                        onEditingChanged: { editing in
                            if !editing, let pos = dragPosition {
                                manager.seek(to: pos)
                                // Keep dragPosition alive briefly so the UI doesn't jump
                                // back before MediaRemote confirms the seek.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    dragPosition = nil
                                }
                            }
                        }
                    )
                    .tint(Color.nonShockingWhite.opacity(0.8))
                    .frame(maxWidth: .infinity)

                    HStack {
                        Text(formatTime(pos))
                            .font(.system(size: 9, weight: .medium).monospacedDigit())
                            .opacity(0.5)
                        Spacer()
                        Text(formatTime(dur))
                            .font(.system(size: 9, weight: .medium).monospacedDigit())
                            .opacity(0.5)
                    }
                }
            }
            .transition(.scaleAndBlur)
        }
    }
}
