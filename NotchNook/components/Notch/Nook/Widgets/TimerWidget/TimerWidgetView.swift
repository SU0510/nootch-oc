//
//  TimerWidgetView.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import SwiftUI

struct TimerWidgetView: View {
    var arrayPosition: ArrayPosition
    var internalPadding: Double

    @Environment(\.timerWidgetSettings) private var prefs
    @State private var store = NookTimersStore.shared
    @State private var showingCreator: Bool = false

    // Extra inset applied to the header row so its content doesn't visually
    // sit directly under the topbar buttons.
    //
    // RIGHT anchor (.last)  → gear button side  — see TopBarContentView.swift, CircleButton ~27 pt
    // LEFT  anchor (.first) → Nook/Tray tabs    — see TopBarTabsView.swift (two ~30 pt tab pills)
    //
    // We use TopBarView.liveActionWidth (35) for the gear side (slightly generous so
    // the MiniPlayerView that may also appear doesn't clip) and a custom constant for
    // the tabs side (~60 pt covers both tab pills + their HStack spacing).
    private static let gearSideInset:  CGFloat = TopBarView.liveActionWidth   // 35
    private static let tabsSideInset:  CGFloat = 60

    private var headerLeadingPad: CGFloat {
        (arrayPosition == .first || arrayPosition == .single) ? Self.tabsSideInset : 4
    }
    private var headerTrailingPad: CGFloat {
        (arrayPosition == .last || arrayPosition == .single) ? Self.gearSideInset : 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header row
            HStack {
                Label("Timers", systemImage: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingCreator.toggle()
                    }
                } label: {
                    Image(systemName: showingCreator ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(showingCreator ? 0.5 : 0.8))
                        .symbolEffect(.bounce, value: showingCreator)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, headerLeadingPad)
            .padding(.trailing, headerTrailingPad)

            // Creator form
            if showingCreator {
                TimerCreatorView(isShowing: $showingCreator)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.92, anchor: .top).combined(with: .opacity)
                    ))
            }

            // Timer list
            if store.timers.isEmpty && !showingCreator {
                // Empty state
                VStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.white.opacity(0.25))
                    Text("No timers running")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.3))
                    Button("Add Timer") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingCreator = true
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous).fill(Color.white.opacity(0.08))
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(store.timers) { entry in
                            TimerRowView(entry: entry)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .scale(scale: 0.9).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .animation(.spring(duration: 0.3), value: store.timers.map { $0.id })
            }
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: internalPadding)
        .frame(prefs.size.screenPtsCGSize, .leading)
    }
}
