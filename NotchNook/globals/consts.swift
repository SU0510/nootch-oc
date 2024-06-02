//
//  consts.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import Foundation

let appleMusicURL = URL(fileURLWithPath: "/System/Applications/Music.app")
let globalAppsRecommentations: [AppRecommendation] = [
    AppRecommendation(
        image: .loRainLogo,
        title: "lo-rain",
        description: "Animated wallpapers and overlay effects for macOS.",
        url: URL(string: "https://lo.cafe/lo-rain")!
    ),
    AppRecommendation(
        image: .winstonLogo,
        title: "Winston",
        description: "A beautiful and native Reddit client app for iOS.",
        url: URL(string: "https://winston.cafe")!
    )
]
