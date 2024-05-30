//
//  PreferencesProtocol.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

protocol Preferences: Equatable, Hashable, Codable, Defaults.Serializable {}
