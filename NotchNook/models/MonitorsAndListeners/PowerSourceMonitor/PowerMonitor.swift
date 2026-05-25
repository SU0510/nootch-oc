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

    private enum Bucket: Equatable {
        case noHardware
        case charging(pct: Int)
        case onBattery(pct: Int)
        case full          // 100 % and plugged
        case low(pct: Int) // below threshold and unplugged
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
        settingsTask = Task {
            for await _ in Defaults.updates(.batteryLiveActivitySettings) {
                // settings changed — re-evaluate low-battery sticky state
                if let current = status {
                    let settings = Defaults[.batteryLiveActivitySettings]
                    let bucket = makeBucket(pct: current.percentage, isCharging: current.isCharging, threshold: settings.lowBatteryThreshold)
                    if case .low = bucket {
                        // still low — keep LA active (it may have been dismissed if threshold changed)
                        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
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
        if isCharging               { return .charging(pct: pct) }
        if pct < threshold          { return .low(pct: pct) }
        return .onBattery(pct: pct)
    }

    private func evaluateTransition(pct: Int, isCharging: Bool) {
        let settings = Defaults[.batteryLiveActivitySettings]
        let newBucket = makeBucket(pct: pct, isCharging: isCharging, threshold: settings.lowBatteryThreshold)

        defer { previousBucket = newBucket }

        guard newBucket != previousBucket else {
            // No bucket change — just update the low-battery sticky if still low
            if case .low = newBucket {
                ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
            }
            return
        }

        switch newBucket {
        case .charging where settings.showWhenPluggedIn:
            fireTransient()
        case .onBattery where settings.showWhenUnplugged:
            fireTransient()
        case .full where settings.showWhenFullyCharged:
            fireTransient()
        case .low where settings.showLowBatteryWarning:
            // Sticky — cancel any pending dismiss and keep inserting
            TimersManager.shared.removeTimer("BatteryActivityDismiss")
            ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
        default:
            // Exiting low (battery charged above threshold or plugged in)
            if case .low = previousBucket ?? newBucket {
                // Was low, now not — dismiss sticky
                ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.batteryVisualizer)
            }
        }
    }

    private func fireTransient() {
        // Cancel any existing dismiss timer so it restarts fresh
        TimersManager.shared.removeTimer("BatteryActivityDismiss")
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
        TimersManager.shared.addTimer("BatteryActivityDismiss", delay: 4) { _ in
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.batteryVisualizer)
        }
    }
}
