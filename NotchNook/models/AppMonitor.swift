//
//  AppMonitor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI
import Cocoa

class AppMonitor: NSObject {
    private let bundleID: String
    private let onAppLaunch: () -> Void
    private let onAppTerminate: () -> Void

    init(bundleID: String, onAppLaunch: @escaping () -> Void, onAppTerminate: @escaping () -> Void) {
        self.bundleID = bundleID
        self.onAppLaunch = onAppLaunch
        self.onAppTerminate = onAppTerminate
        super.init()
        
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(appDidLaunch(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidTerminate(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        
        // Check if the app is already running
        checkIfAppIsAlreadyRunning()
    }

    private func checkIfAppIsAlreadyRunning() {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == bundleID }
        if isRunning {
            onAppLaunch()
        }
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == bundleID else { return }
        onAppLaunch()
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == bundleID else { return }
        onAppTerminate()
    }

    deinit {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.removeObserver(self)
    }
}
