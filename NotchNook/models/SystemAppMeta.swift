//
//  SystemAppMeta.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/07/24.
//

import Cocoa

struct SystemAppMeta: Equatable, Identifiable {
    static func == (lhs: SystemAppMeta, rhs: SystemAppMeta) -> Bool {
        lhs.bundleId == rhs.bundleId
    }
    
    var id: String { bundleId }
    var bundleId = ""
    var name = ""
    var icon = NSImage()
    
    init() {}
    
    init(pid: Int32) {
        guard let app = getAppForProcess(pid: pid),
              let bundleId = app.bundleIdentifier,
              let name = app.localizedName,
              let icon = app.icon else {
            return
        }
        
        self.bundleId = bundleId
        self.name = name
        self.icon = icon
    }
    
    init(bundleId: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
              let bundle = Bundle(url: appURL),
              let name = bundle.infoDictionary?["CFBundleName"] as? String else {
            return
        }
        self.bundleId = bundleId
        self.name = name
        self.icon = NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    func getAppForProcess(pid: pid_t) -> NSRunningApplication? {
        guard let process = NSRunningApplication(processIdentifier: pid) else {
            print("Process not found")
            return nil
        }
        
        func findParentApp(from url: URL) -> NSRunningApplication? {
            var currentURL = url
            while currentURL.pathComponents.count > 1 {
                if currentURL.pathExtension == "app" {
                    if let bundleID = Bundle(url: currentURL)?.bundleIdentifier,
                       let parentApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                        return parentApp
                    }
                }
                currentURL = currentURL.deletingLastPathComponent()
            }
            return nil
        }
        
        if process.bundleURL?.absoluteString.contains("//System/Library/Frameworks/") ?? false {
            if let safariApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first {
                return safariApp
            }
            return nil
        } else if process.bundleURL?.pathExtension == "xpc",
                  let executableURL = process.executableURL,
                  let parentApp = findParentApp(from: executableURL) {
            // This is likely an XPCService or similar, return the parent app's icon
            return parentApp
        } else {
            // This is a regular application, return its icon
            return process
        }
    }
    
    func openApp() {
        NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleId, options: [], additionalEventParamDescriptor: nil, launchIdentifier: nil)
    }
}
