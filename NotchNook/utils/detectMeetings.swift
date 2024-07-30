//
//  detectMeetings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation
import SwiftUI
import EventKit

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

func detectMeetings(in event: EKEvent?) -> Meeting? {
    guard let event else { return nil }
    let patterns: [VideoConferenceService: String] = [
        .googleMeet: "https?://meet\\.google\\.com/[a-zA-Z0-9-]+",
        .zoom: "https?://[\\w-]+\\.zoom\\.us/j/[0-9]+(?:\\?[\\w=&.]+)?",
        .microsoftTeams: "https?://teams\\.microsoft\\.com/l/meetup-join/[\\w-/%]+",
        .webex: "https?://[\\w-]+\\.webex\\.com/[\\w-]+/j\\.php\\?MTID=[a-zA-Z0-9]+"
    ]
    
    for (service, pattern) in patterns {
        if let (text, range) = range(of: pattern, for: event.location) ?? range(of: pattern, for: event.notes), let range {
            let url = String(text[range])
            return Meeting(url: url, service: service)
        }
    }
    
    func range(of pattern: String, for string: String?) -> (String, Range<String.Index>?)? {
        guard let string else { return nil }
        return (string, string.range(of: pattern, options: .regularExpression))
    }
    
    return nil
}
