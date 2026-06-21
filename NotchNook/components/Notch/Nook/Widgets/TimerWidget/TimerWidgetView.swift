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

/// Interior content insets for the timer widget, derived entirely from shared
/// Nook values so the widget honours the SAME bounds/padding contract as every
/// other widget — no bespoke magic numbers:
///   • `top`       — the notch top-bar chrome (`TopBarView.buttonsVisualBottom`),
///                   the line below which content must start to clear the gear/tabs.
///   • `bottom`    — the user's inter-widget padding (`widgetsPadding`).
///   • `leading` / `trailing` — a small interior gutter (half the widget padding),
///                   widened on a position's OUTER edge to clear the Nook's rounded
///                   bottom corner. That corner radius is the exact value
///                   `NoteShapeModifier` rounds to (`maxNotchRadius - contentPadding`),
///                   so the timer insets track the same geometry the notes cards do.
struct TimerInsets {
    let top: CGFloat
    let bottom: CGFloat
    let leading: CGFloat
    let trailing: CGFloat

    init(arrayPosition: ArrayPosition, contentPadding: Double, widgetPadding: Double) {
        // Interior gutter every edge gets, before corner clearance.
        let gutter = CGFloat(widgetPadding) * 0.5
        // The Nook's rounded outer bottom corner (same as the notes cards). An
        // element on that side must inset to its centre to stay clear of the arc.
        let cornerSafe = max(gutter, CGFloat(NotchShape.maxNotchRadius - contentPadding) * 0.5)

        self.top = TopBarView.buttonsVisualBottom
        self.bottom = CGFloat(widgetPadding)
        self.leading  = (arrayPosition == .first || arrayPosition == .single) ? cornerSafe : gutter
        self.trailing = (arrayPosition == .last  || arrayPosition == .single) ? cornerSafe : gutter
    }
}

struct TimerWidgetView: View {
    var arrayPosition: ArrayPosition
    var internalPadding: Double

    @Environment(\.timerWidgetSettings) private var prefs
    @Environment(\.generalSettings) private var generalSettings
    @State private var store = NookTimersStore.shared
    @State private var showingCreator: Bool = false

    /// All interior content insets, derived from the SAME values the rest of the
    /// Nook uses (the top-bar chrome constant, the user's widget padding, and the
    /// real notch corner radius) instead of bespoke literals. See `TimerInsets`.
    private var insets: TimerInsets {
        TimerInsets(arrayPosition: arrayPosition,
                    contentPadding: generalSettings.contentPadding,
                    widgetPadding: internalPadding)
    }

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
                .padding(.top, insets.top)
                .padding(.bottom, insets.bottom)
                .padding(.leading, insets.leading)
                .padding(.trailing, insets.trailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }

            // 2. Creator panel.
            if showingCreator {
                TimerCreatorView(
                    isShowing: $showingCreator,
                    insets: insets
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
        // Width comes from the grid (keeps column/divider math identical to the
        // other widgets), but the HEIGHT fills whatever band the Nook gives us
        // rather than forcing our own grid height. NookView clips the widget row
        // to `nookSettings.size.height` and centres it; pinning our own (taller)
        // grid height there made bottom-anchored content — the Play button — spill
        // past the Nook's visible bottom edge. Filling the available height keeps
        // every edge inside the Nook regardless of the grid-height mismatch.
        .frame(width: prefs.size.width.screenPoints, alignment: .leading)
        .frame(maxHeight: .infinity)
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
            .padding(.trailing, insets.trailing)
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
