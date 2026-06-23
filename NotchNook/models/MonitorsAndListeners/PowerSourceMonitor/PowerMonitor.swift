//
//  PowerMonitor.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/13/24.
//

import IOKit
import IOKit.ps
import Foundation
import Defaults
import SwiftUI

@Observable
class PowerMonitor {
    static let shared = PowerMonitor()

    // MARK: - BatteryStatus

    struct BatteryStatus: Equatable {
        let percentage: Int
        let isCharging: Bool
        let minutesUntilEmpty: Int?
        let minutesUntilFull: Int?

        var formattedTimeRemaining: String {
            guard isCharging else {
                guard let minutesUntilEmpty = minutesUntilEmpty, minutesUntilEmpty > 0 else { return "" }
                return minutesUntilEmpty < 60 ? "\(minutesUntilEmpty)m" : "\(minutesUntilEmpty / 60)h"
            }
            return "\(percentage)%"
        }
    }

    // MARK: - Transition bucket (drives LA event detection)

    // NOTE: buckets must NOT carry the exact percentage. They drive transient-LA
    // *transition* detection (`newBucket != previousBucket`), so any per-percent
    // payload would make every 1 % change look like a new bucket and re-fire the
    // quick peek on each tick while charging/draining. The percentage is read
    // straight from `status` by the views — it never needs to live here.
    private enum Bucket: Equatable {
        case noHardware
        case charging      // plugged in, below 100 %
        case onBattery     // unplugged, at/above threshold
        case full          // 100 % and plugged
        case low           // below threshold and unplugged
    }

    // MARK: - State

    /// `nil` when running on a desktop Mac with no internal battery.
    private(set) var status: BatteryStatus?

    /// `false` on a desktop Mac — the feature is a no-op.
    private(set) var isApplicable: Bool = true

    private var runLoopSource: CFRunLoopSource?
    private var timer: Timer?         // kept only so deinit can invalidate
    private var previousBucket: Bucket?
    private var startupSuppressActive = true
    private var settingsTask: Task<Void, Never>?

    // MARK: - Init / deinit

    private init() {
        setupPowerSourceMonitoring()
        // 2 s startup-suppress window, mirrors BluetoothManager pattern
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            startupSuppressActive = false
        }
        settingsTask = Task { @MainActor in
            for await _ in Defaults.updates(.batteryLiveActivitySettings) {
                // settings changed — re-evaluate low-battery sticky state
                if let current = status {
                    let settings = Defaults[.batteryLiveActivitySettings]
                    let bucket = makeBucket(pct: current.percentage, isCharging: current.isCharging, threshold: settings.lowBatteryThreshold)
                    if case .low = bucket {
                        // still low — keep LA active (it may have been dismissed if threshold changed)
                        ActiveLiveActivitiesManager.shared.insertSync(.batteryVisualizer)
                    }
                }
            }
        }
    }

    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        timer?.invalidate()
        settingsTask?.cancel()
    }

    // MARK: - Setup

    private func setupPowerSourceMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let source = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            Unmanaged<PowerMonitor>.fromOpaque(ctx).takeUnretainedValue().refresh()
        }, context)?.takeRetainedValue()

        if let source {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = source
        }
        refresh()
    }

    // MARK: - Refresh (called on every IOKit power-source notification)

    func refresh() {
        let powerInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSources = IOPSCopyPowerSourcesList(powerInfo).takeRetainedValue() as Array

        // Desktop Mac — no internal battery in the source list
        guard let powerSource = powerSources.first,
              let desc = IOPSGetPowerSourceDescription(powerInfo, powerSource)
                  .takeUnretainedValue() as? [String: Any]
        else {
            isApplicable = false
            status = nil
            return
        }

        isApplicable = true
        let pct      = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
        let newStatus = BatteryStatus(
            percentage:        pct,
            isCharging:        charging,
            minutesUntilEmpty: desc[kIOPSTimeToEmptyKey] as? Int,
            minutesUntilFull:  desc[kIOPSTimeToFullChargeKey] as? Int
        )
        status = newStatus

        guard !startupSuppressActive else {
            // On launch: seed previousBucket silently, don't fire any LA.
            let settings = Defaults[.batteryLiveActivitySettings]
            previousBucket = makeBucket(pct: pct, isCharging: charging, threshold: settings.lowBatteryThreshold)
            return
        }

        evaluateTransition(pct: pct, isCharging: charging)
    }

    // MARK: - Transition detection

    private func makeBucket(pct: Int, isCharging: Bool, threshold: Int) -> Bucket {
        if pct >= 100 && isCharging { return .full }
        if isCharging               { return .charging }
        if pct < threshold          { return .low }
        return .onBattery
    }

    private func evaluateTransition(pct: Int, isCharging: Bool) {
        let settings = Defaults[.batteryLiveActivitySettings]
        let newBucket = makeBucket(pct: pct, isCharging: isCharging, threshold: settings.lowBatteryThreshold)

        defer { previousBucket = newBucket }

        guard newBucket != previousBucket else {
            // No bucket change — just update the low-battery sticky if still low
            if case .low = newBucket {
                DispatchQueue.main.async {
                    ActiveLiveActivitiesManager.shared.insertSync(.batteryVisualizer)
                }
            }
            return
        }

        switch newBucket {
        case .charging where settings.showWhenPluggedIn:
            // Plugged in (or started charging from onBattery/low)
            fireTransient()
        case .onBattery where settings.showWhenUnplugged:
            // Unplugged — covers both charging→onBattery and full→onBattery
            fireTransient()
        case .full where settings.showWhenFullyCharged:
            fireTransient()
        case .low where settings.showLowBatteryWarning:
            // Sticky — cancel any pending dismiss and keep inserting
            DispatchQueue.main.async {
                TimersManager.shared.removeTimer("BatteryActivityDismiss")
                ActiveLiveActivitiesManager.shared.insertSync(.batteryVisualizer)
            }
        default:
            // Handle full→onBattery unplug when showWhenUnplugged is off,
            // and exiting low (battery charged above threshold or plugged in).
            if case .low = previousBucket ?? newBucket {
                // Was low, now not — dismiss sticky
                DispatchQueue.main.async {
                    ActiveLiveActivitiesManager.shared.removeSync(.batteryVisualizer)
                }
            }
        }
    }

    private func fireTransient() {
        // All mutations are funnelled through DispatchQueue.main.async so that:
        //   1. insertSync/_activeLiveActivities is mutated on @MainActor, meaning
        //      the view sees the new set in the SAME layout pass that expands the
        //      notch — no more "notch grows but content is empty" race.
        //   2. The dismiss timer is scheduled on the main RunLoop (Timer.scheduledTimer
        //      called from a bare DispatchQueue thread silently drops because that
        //      thread has no run loop).
        DispatchQueue.main.async {
            TimersManager.shared.removeTimer("BatteryActivityDismiss")
            ActiveLiveActivitiesManager.shared.insertSync(.batteryVisualizer)
            // Build timer and add to the main RunLoop in .common mode so it fires
            // even while the user is scrolling / interacting with a modal sheet.
            // (Timer.scheduledTimer only adds to .default mode of current run loop.)
            let dismissTimer = Timer(timeInterval: 4, repeats: false) { _ in
                MainActor.assumeIsolated { ActiveLiveActivitiesManager.shared.removeSync(.batteryVisualizer) }
            }
            RunLoop.main.add(dismissTimer, forMode: .common)
            TimersManager.shared.replaceMainThreadTimer("BatteryActivityDismiss", timer: dismissTimer)
        }
    }
}
