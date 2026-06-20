//
//  TimerHaptics.swift
//  NotchNook
//
//  Created by Kinark on 20/06/26.
//

import AppKit
import Defaults

// MARK: - TimerWheelUnit

enum TimerWheelUnit { case hours, minutes, seconds }

// MARK: - TimerHaptics
//
// Haptic rhythm design — all patterns built from the three macOS Force Touch
// primitives (.generic / .alignment / .levelChange) via sequencing + timing.
//
// Hours   — "heavy/chunky": two .generic performs 40 ms apart (double-thud).
//            High inertia feel; each tick has more physical mass.
// Minutes — "medium/crisp":  one .alignment perform.
//            More precise and decisive than .generic; sits between the two.
// Seconds — "light/fast":    one .levelChange perform.
//            The lightest primitive; suits the rapid high-cadence seconds wheel.
// Lock    — two .levelChange performs 80 ms apart — a calm, conclusive double-click
//            that is audibly distinct from any tick pattern.
//
// Throttle: per-unit minimum interval of 16 ms (~60 Hz cap) prevents haptic
// pile-up during fast scrolls. The hours double-burst schedules its trailing
// hit with DispatchQueue.main.asyncAfter, which is safe because
// NSHapticFeedbackManager.defaultPerformer is fire-and-forget.

@MainActor final class TimerHaptics {

    static let shared = TimerHaptics()

    // Per-unit timestamps for throttle guard.
    private var lastTick: [TimerWheelUnit: Date] = [:]
    private let tickMinInterval: TimeInterval = 0.016   // ~60 Hz

    private let performer = NSHapticFeedbackManager.defaultPerformer
    private let settings   = InMemoryDefault(key: .generalSettings)

    private init() {}

    // MARK: - Public API

    /// Fire once per integer tick while scrolling a wheel. Pattern differs per unit.
    func tick(_ unit: TimerWheelUnit) {
        guard !settings.value.disableHaptics else { return }
        guard shouldFire(unit) else { return }

        switch unit {
        case .hours:
            // Double-thud: two heavy .generic hits 40 ms apart.
            performer.perform(.generic, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.040) { [weak self] in
                guard let self, !self.settings.value.disableHaptics else { return }
                self.performer.perform(.generic, performanceTime: .now)
            }

        case .minutes:
            // Single crisp .alignment — medium weight, precise.
            performer.perform(.alignment, performanceTime: .now)

        case .seconds:
            // Single light .levelChange — quick, airy.
            performer.perform(.levelChange, performanceTime: .now)
        }
    }

    /// Fire when the pill magnetically locks onto a new wheel column.
    func lock() {
        guard !settings.value.disableHaptics else { return }
        // Decisive double .levelChange — calm, conclusive, clearly not a tick.
        performer.perform(.levelChange, performanceTime: .now)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.080) { [weak self] in
            guard let self, !self.settings.value.disableHaptics else { return }
            self.performer.perform(.levelChange, performanceTime: .now)
        }
    }

    // MARK: - Private

    private func shouldFire(_ unit: TimerWheelUnit) -> Bool {
        let now = Date()
        if let last = lastTick[unit], now.timeIntervalSince(last) < tickMinInterval {
            return false
        }
        lastTick[unit] = now
        return true
    }
}
