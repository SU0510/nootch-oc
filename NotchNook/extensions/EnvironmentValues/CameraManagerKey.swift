//
//  CameraManagerKey.swift
//  NotchNook
//
//  Created by Lori Montenegro on 28/08/24.
//

import SwiftUI

private struct CameraManagerKey: EnvironmentKey {
    static let defaultValue = CameraManager()
}

extension EnvironmentValues {
    var cameraManager: CameraManager {
        get { self[CameraManagerKey.self] }
        set { self[CameraManagerKey.self] = newValue }
    }
}
