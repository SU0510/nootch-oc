//
//  IconLabeled.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI

protocol MetaInfo: Hashable, Identifiable {
    var name: String { get }
    var icon: String { get }
    var description: String? { get }
    var isImplemented: Bool { get }
}
