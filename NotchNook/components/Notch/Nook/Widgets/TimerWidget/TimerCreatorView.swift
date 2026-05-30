//
//  TimerCreatorView.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import SwiftUI

struct TimerCreatorView: View {
    @Binding var isShowing: Bool
    @Environment(\.timerWidgetSettings) private var prefs

    @State private var label: String = ""
    @State private var hours: Int = 0
    @State private var minutes: Int = 5
    @State private var seconds: Int = 0
    @State private var labelField: Bool = false

    private let quickPresets: [(label: String, seconds: Int)] = [
        ("1m",  60),
        ("5m",  300),
        ("10m", 600),
        ("25m", 1500),
        ("1h",  3600),
    ]

    private var totalSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Quick presets
            HStack(spacing: 5) {
                ForEach(quickPresets, id: \.seconds) { preset in
                    Button(preset.label) {
                        applyPreset(preset.seconds)
                    }
                    .buttonStyle(PresetButtonStyle())
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Label field
            TextField(prefs.defaultLabel.isEmpty ? "Label (optional)" : prefs.defaultLabel, text: $label)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .foregroundStyle(Color.white)
                .onSubmit { commitIfValid() }

            // Duration picker row
            HStack(spacing: 4) {
                DurationUnitField(value: $hours, label: "h", range: 0...23)
                Text(":").foregroundStyle(Color.white.opacity(0.5)).font(.system(size: 14, weight: .semibold))
                DurationUnitField(value: $minutes, label: "m", range: 0...59)
                Text(":").foregroundStyle(Color.white.opacity(0.5)).font(.system(size: 14, weight: .semibold))
                DurationUnitField(value: $seconds, label: "s", range: 0...59)

                Spacer()

                Button("Start") {
                    commitIfValid()
                }
                .disabled(totalSeconds <= 0)
                .buttonStyle(StartButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func applyPreset(_ secs: Int) {
        hours = secs / 3600
        minutes = (secs % 3600) / 60
        seconds = secs % 60
    }

    private func commitIfValid() {
        guard totalSeconds > 0 else { return }
        let effectiveLabel = label.isEmpty ? prefs.defaultLabel : label
        NookTimersStore.shared.add(label: effectiveLabel, totalSeconds: totalSeconds)
        withAnimation(.spring) { isShowing = false }
        label = ""
    }
}

// MARK: - Sub-components

private struct DurationUnitField: View {
    @Binding var value: Int
    var label: String
    var range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 2) {
            TextField("", value: $value, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.white)
                .frame(width: 28)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
                .onChange(of: value) { _, v in
                    value = max(range.lowerBound, min(range.upperBound, v))
                }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.white.opacity(0.4))
        }
    }
}

private struct PresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.18 : 0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}

private struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
