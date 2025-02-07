//
//  BluetoothManager.swift
//  NotchNook
//
//  Created by Hasan Sultan on 9/2/24.
//

import IOBluetooth
import Defaults
import CoreBluetooth

@Observable
final class BluetoothManager {
    
    static let shared = BluetoothManager()
    
    enum AppleDeviceType: String, CaseIterable {
        case airpodsPro = "AirPods Pro"
        case airpodsMax = "AirPods Max"
        case airpods = "AirPods"
        case magicMouse = "Magic Mouse"
        case magicKeyboard = "Magic Keyboard"
        case magicTrackpad = "Magic Trackpad"
        
        var iconName: String {
            switch self {
                case .airpodsPro: return "airpods.pro"
                case .airpodsMax: return "airpods.max"
                case .airpods: return "airpods"
                case .magicMouse: return "magicmouse"
                case .magicKeyboard: return "keyboard.fill"
                case .magicTrackpad: return "rectangle.and.hand.point.up.left.fill"
            }
        }
    }
    
    enum BluetoothError: Error {
        case permissionDenied
        case deviceNotFound
        case connectionFailed
    }
    
    private static let APPLE_DEVICE_PATTERN = #"(Magic Mouse|AirPods|Magic Keyboard|Magic Trackpad).*"#
    private static let ACTIVITY_DISMISS_TIMER_ID = "BluetoothLiveActivityDismiss"
    
    private(set) var currentDeviceIcon: String = ""
    private(set) var currentDeviceBattery: Int?
    
    @MainActor private var currentDevice: IOBluetoothDevice?
    
    private let appleDeviceIconMap: [String: String] = Dictionary(
        uniqueKeysWithValues: AppleDeviceType.allCases.map { ($0.rawValue, $0.iconName) }
    )
    
    @MainActor private var allConnectedDevices: [IOBluetoothDevice]?
    @MainActor private var appleDevices: [IOBluetoothDevice]?
    @MainActor private var appleDevicesActivelyConnected: [IOBluetoothDevice]?
    
    private init() {
        setupManager()
    }
    
    private func setupManager() {
        requestBluetoothPermissions()
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceConnected(_:withDevice:)))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceDisconnected(_:)),
            name: NSNotification.Name(rawValue: kIOBluetoothDeviceNotificationNameDisconnected),
            object: nil
        )
    }
    
    private func requestBluetoothPermissions() {
        switch CBCentralManager.authorization {
            case .denied, .restricted, .notDetermined:
                MessageUtil.showMessage(
                    title: "Bluetooth Access Required",
                    message: "This functionality needs Bluetooth access to detect your Apple devices. Open Settings to grant permission?"
                ) { action in
                    switch action {
                        case .ok:
                            SystemIntegrationHelper.openBluetoothPreferences()
                            SystemIntegrationHelper.quitApp()
                        case .cancel:
                            self.log("User denied Bluetooth access. App functionality limited.")
                    }
                }
            case .allowedAlways:
                break
            @unknown default:
                log("Unknown Bluetooth authorization status")
        }
    }
    
    @MainActor
    private func updateConnectedDevices() throws {
        guard let devices = IOBluetoothDevice.pairedDevices() else {
            throw BluetoothError.deviceNotFound
        }
        
        let connectedDevices = devices.filter { device in
            guard let device = device as? IOBluetoothDevice else { return false }
            return device.isConnected()
        }.map { $0 as! IOBluetoothDevice }
        
        if appleDevicesActivelyConnected == nil {
            appleDevicesActivelyConnected = []
        }
        
        for device in connectedDevices {
            if !(appleDevicesActivelyConnected?.contains(where: { $0 == device }) ?? false) {
                appleDevicesActivelyConnected?.append(device)
                return
            }
        }
    }
    
    @MainActor
    private func removeDevice(_ disconnectedDevice: IOBluetoothDevice) {
        if disconnectedDevice == currentDevice {
            currentDevice = nil
            currentDeviceIcon = ""
            currentDeviceBattery = 0
        }
        
        appleDevicesActivelyConnected?.removeAll { $0 == disconnectedDevice }
        currentDeviceIcon = getIconForDevice(disconnectedDevice)
    }

    
    private func getIconForDevice(_ device: IOBluetoothDevice) -> String {
        if let deviceName = device.name,
           let matchedDevice = appleDeviceIconMap.first(where: { deviceName.contains($0.key) }) {
            return matchedDevice.value
        }
        return device.deviceClassMajor == kBluetoothDeviceClassMajorAudio ? "headphones" : ""
    }
    
    private func handleDeviceActivity() async {
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.bluetoothDevice)
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.bluetoothDevice)
    }
    
    @objc private func deviceConnected(_ notification: IOBluetoothUserNotification, withDevice device: IOBluetoothDevice) {
        Task { @MainActor in
            do {
                try updateConnectedDevices()
                await updateBatteryLevel(for: device)
                currentDevice = device
                currentDeviceIcon = getIconForDevice(device)
                await handleDeviceActivity()
            } catch {
                log("Failed to update devices: \(error)")
            }
        }
    }
    
    @objc private func deviceDisconnected(_ notification: Notification) {
        guard let device = notification.object as? IOBluetoothDevice else {
            log("Invalid device disconnection notification")
            return
        }
        
        Task { @MainActor in
            removeDevice(device)
            await handleDeviceActivity()
        }
    }
    
    @MainActor
    private func updateBatteryLevel(for targetDevice: IOBluetoothDevice) async {
        // First check
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        if currentDevice == targetDevice {
            checkBatteryLevel(for: targetDevice)
            
            // If battery level is still 0 after first check, try again
            if currentDeviceBattery == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if currentDevice == targetDevice {
                    checkBatteryLevel(for: targetDevice)
                }
            }
        }
    }
    
    @MainActor
    private func checkBatteryLevel(for targetDevice: IOBluetoothDevice) {
        var iterator = io_iterator_t()
        var object: io_object_t
        
        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        
        guard result == KERN_SUCCESS else {
            log("Failed to get matching services")
            return
        }
        
        defer {
            IOObjectRelease(iterator)
        }
        
        var foundDevice = false
        repeat {
            object = IOIteratorNext(iterator)
            guard object != 0 else { break }
            
            defer {
                IOObjectRelease(object)
            }
            
            var propsRef: Unmanaged<CFMutableDictionary>?
            let status = IORegistryEntryCreateCFProperties(object, &propsRef, kCFAllocatorDefault, 0)
            
            guard status == KERN_SUCCESS,
                  let props = propsRef?.takeRetainedValue() as? [String: Any] else {
                continue
            }
            
            if let address = props["DeviceAddress"] as? String,
               let percent = props["BatteryPercent"] as? Int {
                
                if address.lowercased() == targetDevice.addressString.lowercased() {
                    currentDeviceBattery = percent
                    foundDevice = true
                    log("Battery level found for device: \(targetDevice.name ?? "Unknown") - \(percent)%")
                    break
                }
            }
        } while !foundDevice
        
        if !foundDevice {
            log("Battery level not found for device: \(targetDevice.name ?? "Unknown")")
            currentDeviceBattery = 0
        }
    }
    
    private func log(_ message: String) {
#if DEBUG
        print("[BluetoothManager] \(message)")
#endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
