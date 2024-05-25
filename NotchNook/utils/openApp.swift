//
//  openApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/05/24.
//

import AppKit

func openApp(_ bundleID: String) {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
        print("Application with Bundle ID \(bundleID) not found.")
        return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    
    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { (app, error) in
        if let error = error {
            print("Failed to launch application: \(error)")
        } else {
            print("Application launched successfully.")
        }
    }
}
