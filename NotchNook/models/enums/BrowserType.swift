//
//  BrowserType.swift
//  NotchNook
//
//  Created by Lori Montenegro on 08/07/25.
//

enum BrowserType: String, CaseIterable {
    case safari = "com.apple.Safari"
    case chrome = "com.google.Chrome"
    case firefox = "org.mozilla.firefox"
    case edge = "com.microsoft.edgemac"
    case opera = "com.operasoftware.Opera"
    case brave = "com.brave.Browser"
    case vivaldi = "com.vivaldi.Vivaldi"
    case duckDuckGo = "com.duckduckgo.macos"
    case tor = "org.torproject.torbrowser"
    case yandex = "ru.yandex.desktop.yandex-browser"
    
    static func browserKeywords() -> [String] {
        return ["safari", "chrome", "firefox", "edge", "opera", "brave", "vivaldi", "duckduckgo", "tor", "browser", "yandex"]
    }
    
    static func getBrowserBundleId(for appName: String) -> String? {
        let lowercasedAppName = appName.lowercased()
        
        for keyword in browserKeywords() {
            if lowercasedAppName.contains(keyword) {
                for browserType in BrowserType.allCases {
                    if browserType.rawValue.lowercased().contains(keyword) {
                        return browserType.rawValue
                    }
                }
            }
        }
        
        return nil
    }
}
