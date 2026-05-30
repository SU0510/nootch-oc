//
//  TimerRowView.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import SwiftUI

struct TimerRowView: View {
    var entry: TimerEntry
    @Environment(\.timerWidgetSettings) private var prefs

    private var isExpired: Bool { entry.state == .expired }

    private var countdownText: String {
        let s = entry.remainingSeconds
        if prefs.showSeconds {
            let h = s / 3600
            let m = (s % 3600) / 60
            let sec = s % 60
            if h > 0 {
                return String(format: "%d:%02d:%02d", h, m, sec)
            } else {
                return String(format: "%d:%02d", m, sec)
            }
        } else {
            let h = s / 3600
            let m = (s % 3600) / 60
            if h > 0 {
                return "\(h)h \(m)m"
            } else {
                return "\(max(m, 0))m"
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {

            // State icon (colorblind-safe: shape + symbol conveys meaning)
            Image(systemName: isExpired ? "timer" : (entry.state == .paused ? "pause.fill" : "timer"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isExpired ? Color.red : Color.white.opacity(0.75))
                .frame(width: 14)

            // Label + countdown
            VStack(alignment: .leading, spacing: 0) {
                if !entry.label.isEmpty {
                    Text(entry.label)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(isExpired ? Color.red : Color.white.opacity(0.6))
                }
                Text(isExpired ? "Done" : countdownText)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(isExpired ? Color.red : Color.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Controls
            HStack(spacing: 4) {
                if isExpired {
                    Button {
                        NookTimersStore.shared.dismissExpired(entry)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                } else {
                    // Pause / Resume
                    Button {
                        if entry.state == .running {
                            NookTimersStore.shared.pause(entry)
                        } else {
                            NookTimersStore.shared.resume(entry)
                        }
                    } label: {
                        Image(systemName: entry.state == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    // Cancel
                    Button {
                        NookTimersStore.shared.cancel(entry)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isExpired ? Color.red.opacity(0.15) : Color.white.opacity(0.07))
        )
        .animation(.easeInOut(duration: 0.25), value: isExpired)
    }
}
