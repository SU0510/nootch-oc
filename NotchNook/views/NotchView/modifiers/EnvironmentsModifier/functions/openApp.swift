//
//  openApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI

extension NotchView.EnvironmentsModifier {
    func openApp(_ bundleID: String) {
        preventNextFocusFrontmostWindow()
        
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
}
