//
//  TimersManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/07/24.
//

import SwiftUI

class TimersManager {
    static let shared = TimersManager()
    private init() {}
    private var timersDict = [String: Timer]()
    let dispatchQueue = DispatchQueue(label: "TimersManager")
    
    func addTimer(_ id: String, delay: Double, cb: @escaping (Timer) -> ()) {
        dispatchQueue.sync {
            if let foundTimer = timersDict[id] { foundTimer.invalidate() }
            timersDict[id] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
                cb(timer)
                self.timersDict.removeValue(forKey: id)
            }
        }
    }
    
    func removeTimer(_ id: String) {
        dispatchQueue.sync {
            if let foundTimer = timersDict[id] { foundTimer.invalidate() }
            timersDict.removeValue(forKey: id)
        }
    }
}
