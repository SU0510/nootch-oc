//
//  InMemoryDefault.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI
import Foundation
import Defaults

final class InMemoryDefault<T: Defaults.Serializable> {
    private var key: Defaults.Key<T>
    var value: T {
        didSet {
            Defaults[key] = value
        }
    }
    private var task: Task<(), Never>?

    init(key: Defaults.Key<T>) {
        self.key = key
        self.value = Defaults[key]
        task = Task {
            for await value in Defaults.updates(key) {
                self.value = value
            }
        }
    }

    deinit {
        task?.cancel()
    }
}
