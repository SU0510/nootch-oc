//
//  NotificationObserverHelper.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI

class NotificationObserverHelper {
    var closure: ((Notification) -> Void)?

    init(notificationName: String, closure: @escaping (Notification) -> Void) {
        self.closure = closure
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleNotification(_:)),
            name: NSNotification.Name(rawValue: notificationName),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    @objc func handleNotification(_ notification: Notification) {
        closure?(notification)
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
