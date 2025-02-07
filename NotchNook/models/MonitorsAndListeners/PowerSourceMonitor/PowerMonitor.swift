//
//  PowerMonitor.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/13/24.
//

import IOKit
import Foundation
import Defaults

@Observable
class PowerMonitor {
    static let shared = PowerMonitor()
    
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
            
//            if let minutesUntilFull = minutesUntilFull, minutesUntilFull > 0 {
//                return minutesUntilFull > 60 ? "\(minutesUntilFull / 60)h" : "\(minutesUntilFull)m"
//            }
//            return ""
            return "\(percentage)%"
        }
    }
    
    private var timer: Timer?
    private var runLoopSource: CFRunLoopSource?
    
    // Callback for UI updates
    var status: BatteryStatus?
    
    init() {
        setupPowerSourceMonitoring()
    }
    
    private func setupPowerSourceMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.updatePowerStatus()
        }, context)?.takeRetainedValue()
        
        if let source = source {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
            self.runLoopSource = source
            updatePowerStatus()
        }
    }
    
    private func updatePowerStatus() {
        let powerInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSources = IOPSCopyPowerSourcesList(powerInfo).takeRetainedValue() as Array
        
        guard let powerSource = powerSources.first,
              let description = IOPSGetPowerSourceDescription(powerInfo, powerSource).takeUnretainedValue() as? [String: Any] else {
            return
        }
        
        let status = BatteryStatus(
            percentage: description[kIOPSCurrentCapacityKey] as? Int ?? 0,
            isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
            minutesUntilEmpty: description[kIOPSTimeToEmptyKey] as? Int,
            minutesUntilFull: description[kIOPSTimeToFullChargeKey] as? Int
        )
        
        self.status = status
        updateLiveActivity()
    }
    
    private func updateLiveActivity() {
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
        
        // Auto-dismiss after timeout
        TimersManager.shared.addTimer("BatteryActivity", delay: 3) { _ in
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.batteryVisualizer)
        }
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
        timer?.invalidate()
    }
}
