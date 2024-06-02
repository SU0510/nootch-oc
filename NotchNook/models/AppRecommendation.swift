//
//  AppRecommendation.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import Foundation
import SwiftUI

struct AppRecommendation: Identifiable {
    var id: String { self.title }
    var image: ImageResource
    var title: String
    var description: String
    var url: URL
}
