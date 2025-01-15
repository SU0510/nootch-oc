//
//  PowerSourceMonitor.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/13/24.
//

import IOKit
import Foundation
import Defaults


class PowerSourceMonitor {
    static let shared = PowerSourceMonitor()
    public var powerInfoStruct = PowerInfoStruct()
    private var runLoopSource: CFRunLoopSource?
    private var localTimer: Timer?
    private var elapsedTime: UInt = 0
    private var targetTime: UInt?
    private var inactivityTimeoutInSecs: Double = 0
    
    init () {
        setupPowerSourceListener()
        self.inactivityTimeoutInSecs = Defaults[.liveActivitiesSettings].inactivityTimeoutInSecs
    }
    
    private func startTimer() {
        if self.localTimer != nil {
            stopTimer()
        }
        self.localTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1 // Every one second
        }
        setCorrectTargetTimeSource()
    }
    
    private func setCorrectTargetTimeSource () {
        if self.powerInfoStruct.ACPower != nil {
            self.targetTime = Defaults[.batteryLiveActivitySettings].notifyOnChargePercentage
        }
        else {
            self.targetTime = Defaults[.batteryLiveActivitySettings].notifyTimeLeftOnBattery
        }
    }
    
    private func stopTimer() {
        localTimer?.invalidate()
        localTimer = nil
    }
    
    func setupPowerSourceListener() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let source = IOPSNotificationCreateRunLoopSource({(context) in
            guard let context = context else {return}
            let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            
            monitor.powerSourceChanged(context: context)
        }, context)?.takeRetainedValue()
        
        if let source = source {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
            self.runLoopSource = source
        }
        powerSourceChanged(context: context) // Required to set the first set of info as the application runs
        print(Date(), "Observing Power Sources")
    }
    
    func stopPowerSourceListener () {
        powerInfoStruct.ACPower =  nil
        powerInfoStruct.BatteryPower = nil
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
            print(Date(), "Stopped observing power sources")
        }
    }
    
    deinit {
        stopPowerSourceListener()
        stopTimer()
    }
    
    private func powerSourceChanged(context: UnsafeMutableRawPointer?) {
        let powerSourcesInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourcesList = IOPSCopyPowerSourcesList(powerSourcesInfo).takeRetainedValue() as Array
        
        if powerSourcesList.isEmpty {
            return
        }
        
        for ps in powerSourcesList {
            if let powerSource = IOPSGetPowerSourceDescription(powerSourcesInfo, ps).takeUnretainedValue() as? [String: AnyObject] {
                if let powerSourceType = powerSource[kIOPSPowerSourceStateKey] as? String, let powerSourceName = powerSource[kIOPSNameKey] as? String {
                    print("Power source type: \(powerSourceType) name: \(powerSourceName)")
                    if powerSourceType == kIOPSACPowerValue, var timeToCharge = powerSource[kIOPSTimeToFullChargeKey] as? Int,
                       let currentStateOfCharge = powerSource[kIOPSCurrentCapacityKey] as? Int{
                        if timeToCharge == -1 { timeToCharge = 0 }
                        if self.powerInfoStruct.ACPower == nil {
                            // Power connected, computer was potentially charging in the past or first time loading the struct in memory all together
                            self.powerInfoStruct.BatteryPower = nil
                            self.powerInfoStruct = PowerInfoStruct(ACPower: ACPower(name: powerSourceName,timeLeftTo100: timeToCharge, currentStateOfCharge: currentStateOfCharge))
                            self.startTimer()
                            self.firePowerSourceUpdateNotification()
                        } else {
                            if self.powerInfoStruct.ACPower?.timeLeftTo100 == timeToCharge {
                                // No particular change, lets ignore this event
                                return
                            }
                            self.powerInfoStruct.ACPower?.timeLeftTo100 = timeToCharge
                            self.powerInfoStruct.ACPower?.currentStateOfCharge = currentStateOfCharge
                            if elapsedTime >= targetTime! {
                                self.firePowerSourceInfoUpdate()
                            }
                        }
                    } else if powerSourceType == kIOPSBatteryPowerValue, let currentStateOfCharge = powerSource[kIOPSCurrentCapacityKey] as? Int, let isCharging = powerSource[kIOPSIsChargingKey] as? Bool, var timeToEmpty = powerSource[kIOPSTimeToEmptyKey] as? Int {
                        if timeToEmpty == -1 {timeToEmpty = 0}
                        if self.powerInfoStruct.BatteryPower == nil {
                            // First time init or computer came off the AC power to Battery power
                            self.powerInfoStruct.ACPower = nil
                            self.powerInfoStruct = PowerInfoStruct(BatteryPower: BatteryPower(name: powerSourceName, currentStateOfCharge: currentStateOfCharge, isCharging: isCharging, timeToEmpty: timeToEmpty))
                            self.startTimer()
                            self.firePowerSourceUpdateNotification()
                        } else {
                            if self.powerInfoStruct.BatteryPower?.currentStateOfCharge == currentStateOfCharge {
                                // No particular change, lets ignore this event
                                return
                            }
                            // All other aspects that can potentially change
                            self.powerInfoStruct.BatteryPower?.currentStateOfCharge = currentStateOfCharge
                            self.powerInfoStruct.BatteryPower?.isCharging = isCharging
                            self.powerInfoStruct.BatteryPower?.timeToEmpty = timeToEmpty
                            if elapsedTime >= targetTime! {
                                self.firePowerSourceInfoUpdate()
                            }
                        }
                    }
                }
            }
        }
    }
        
    private func firePowerSourceUpdateNotification() {
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
        //NotificationCenter.default.post(name: .powerSourceChanged, object: nil)
        let timerId = "PowerSourceLiveActivityDismiss"
        TimersManager.shared.addTimer(timerId, delay: self.inactivityTimeoutInSecs) { _ in
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.batteryVisualizer)
        }
    }
    
    private func firePowerSourceInfoUpdate() {
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.batteryVisualizer)
        //NotificationCenter.default.post(name: .updatePowerSourceInfo, object: nil)
        let timerId = "PowerSourceInfoLiveActivityDismiss"
        TimersManager.shared.addTimer(timerId, delay: self.inactivityTimeoutInSecs) { _ in
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.batteryVisualizer)
        }
    }
}
