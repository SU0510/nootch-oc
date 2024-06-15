//
//  detectMeetings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation
import SwiftUI

enum VideoConferenceService: String {
    case googleMeet = "Meet"
    case zoom = "Zoom"
    case microsoftTeams = "Teams"
    case webex = "Webex"
    
    var logo: ImageResource {
        return switch self {
            case .googleMeet: .meet
            case .zoom: .zoom
            case .microsoftTeams: .teams
            case .webex: .webex
        }
    }
}

struct Meeting {
    var url: String
    var service: VideoConferenceService
}

func detectMeetings(_ text: String) -> Meeting? {
    let patterns: [VideoConferenceService: String] = [
        .googleMeet: "https?://meet\\.google\\.com/[a-zA-Z0-9-]+",
        .zoom: "https?://[\\w-]+\\.zoom\\.us/j/[0-9]+",
        .microsoftTeams: "https?://teams\\.microsoft\\.com/l/meetup-join/[\\w-/%]+",
        .webex: "https?://[\\w-]+\\.webex\\.com/[\\w-]+/j\\.php\\?MTID=[a-zA-Z0-9]+"
    ]

    for (service, pattern) in patterns {
        if let range = text.range(of: pattern, options: .regularExpression) {
            let url = String(text[range])
            return Meeting(url: url, service: service)
        }
    }

    return nil
}
