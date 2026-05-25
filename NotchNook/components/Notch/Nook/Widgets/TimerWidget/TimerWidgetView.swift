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
            .padding(.horizontal, 4)

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
