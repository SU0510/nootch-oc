//
//  NotchNook.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import SwiftUI
import Defaults

@Observable
class NotchNook {
    static let shared = NotchNook()
    
    var shelf = Shelf()
    var pinned = false
    var activeLiveActivities = Set<LiveActivity>()
    var mode = [UUID:NotchMode]()
    
    enum LiveActivity: String, Hashable, Codable, CaseIterable {
        case media, shelf
        
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
    
    enum NotchMode: String, Hashable {
        case closed, nook, shelf, dragging
    }
}

