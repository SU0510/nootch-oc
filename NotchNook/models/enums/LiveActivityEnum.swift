//
//  LiveActivity.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

enum LiveActivity: String, Codable, MetaInfo, CaseIterable {
    case media, shelf
    
    var id: String { self.rawValue }
    
    var description: String? { nil }
    
    var icon: String {
        return switch self {
        case .media: "music.note"
        case .shelf: "shippingbox.fill"
        }
    }
    
    var name: String {
        return switch self {
        case .media: "Media"
        case .shelf: "Files Box"
        }
    }
}
