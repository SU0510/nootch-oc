//
//  TimerWidgetView.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//  Redesigned 2026-05-30: no header (matches Notes/Todo/etc), creator owns
//  its own close button, idle has a single floating "+" that only shows
//  when the creator is closed. Position-aware bottom-corner insets — the
//  Nook's outer bottom corners are rounded at (maxNotchRadius - contentPadding)
//  = 40 - 12 = 28 pt, so widgets at .last/.single anchor must inset that far
//  from the trailing edge, and .first/.single from the leading edge.
//

import SwiftUI

struct TimerWidgetView: View {
    var arrayPosition: ArrayPosition
    var internalPadding: Double

    @Environment(\.timerWidgetSettings) private var prefs
    @Environment(\.generalSettings) private var generalSettings
    @State private var store = NookTimersStore.shared
    @State private var showingCreator: Bool = false

    private static let topbarSafe: CGFloat = TopBarView.buttonsVisualBottom   // 32

    /// How far an element must inset from the leading edge of the widget to
    /// fully clear the Nook's bottom-left rounded corner.
    private var bottomLeadingSafe: CGFloat {
        guard arrayPosition == .first || arrayPosition == .single else { return 6 }
        return NotchShape.maxNotchRadius - generalSettings.contentPadding * 0.5  // ≈ 34
    }

    /// Same for the trailing edge (bottom-right rounded corner).
    private var bottomTrailingSafe: CGFloat {
        guard arrayPosition == .last || arrayPosition == .single else { return 6 }
        return NotchShape.maxNotchRadius - generalSettings.contentPadding * 0.5
    }

    private static let bottomSafe: CGFloat = 10

    var body: some View {
        ZStack(alignment: .topLeading) {

            // 1. Idle content — only shown when the creator is closed.
            if !showingCreator {
                Group {
                    if store.timers.isEmpty {
                        emptyState
                    } else {
                        timersList
                    }
                }
                .padding(.top, Self.topbarSafe)
                .padding(.bottom, Self.bottomSafe)
                .padding(.leading, max(6, bottomLeadingSafe * 0.4))
                .padding(.trailing, max(6, bottomTrailingSafe * 0.4))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }

            // 2. Creator panel.
            if showingCreator {
                TimerCreatorView(
                    isShowing: $showingCreator,
                    topSafe: Self.topbarSafe,
                    bottomLeadingSafe: bottomLeadingSafe,
                    bottomTrailingSafe: bottomTrailingSafe
                )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96, anchor: .top).combined(with: .opacity),
                        removal:   .scale(scale: 0.96, anchor: .top).combined(with: .opacity)
                    ))
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.timers.isEmpty)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: showingCreator)
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: internalPadding)
        .frame(prefs.size.screenPtsCGSize, .leading)
    }

    // MARK: - Idle subviews

    /// Pill button shared by the empty state and the top of the timer list.
    private var addTimerButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                showingCreator = true
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("Add Timer")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous).fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private var timersList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                // Add button sits at the TOP of the list.
                HStack {
                    addTimerButton
                    Spacer(minLength: 0)
                }
                ForEach(store.timers) { entry in
                    TimerRowView(entry: entry)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal:   .scale(scale: 0.9).combined(with: .opacity)
                        ))
                }
            }
            .padding(.trailing, max(6, bottomTrailingSafe * 0.4))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7),
                   value: store.timers.map { $0.id })
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 24))
                .foregroundStyle(Color.white.opacity(0.28))
            Text("No timers running")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.45))
            addTimerButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
