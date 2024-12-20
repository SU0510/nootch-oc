//
//  PredefinedGIF.swift
//  NotchNook
//
//  Created by Lori Montenegro on 19/12/24.
//

enum PredefinedGIF: String, Codable, Hashable, CaseIterable {
    case gunter, snoopy, lisa, michael
    
    var name: String {
        rawValue.capitalized
    }
}
