//
//  CalendarManagerError.swift
//  NotchNook
//
//  Created by Lori Montenegro on 24/07/24.
//

import EventKit

public enum CalendarManagerError: Error, LocalizedError {
    case mapFromError(Error)
    case unableToAccessCalendar
    case eventAuthorizationStatus(EKAuthorizationStatus? = nil)
    case invalidEvent
    
    var localizedDescription: String {
        switch self {
            case .invalidEvent: return "Invalid event"
            case .unableToAccessCalendar: return "Unable to access calendar"
            case let .mapFromError(error): return error.localizedDescription
            case let .eventAuthorizationStatus(status):
                if let status = status {
                    return "Failed to authorize event permission, status: \(status)"
                } else {
                    return "Failed to authorize event permission"
                }
        }
    }
}
