//
//  consts.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import Foundation
import Lottie

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

let pubKey = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoACCWKAILQ3ljmdgSPOV\n9qu2Si7qzFKVUHLrieaBjuqAZU8Ytuwq5PhXcJBq2s75yE2ijVU4s74SoiswklwD\n1WUEv5LSfDGkUwVKQouAirZJTzgyZqLrz7xwWevQT6zxHdYSyBxNJtyQYicfnMTZ\nIzfX8pYuFPCeX2j6bLw1OkJ56GeALnQOh5FUd76o2VRgwMC1q1Bgiia4cZYbdu9a\nSF1hVYX1BAsatSQpaAkKyuXh4lrXiK6UFEt4OLSFSohbbV/1boG9j3CPgNUOMulw\nAoeRgc81iFey0CE6bLLP1tXKmU0Hfo5xKus7/QgsrSNslqWNr3pKV/H8cE1Atvtf\npQIDAQAB\n-----END PUBLIC KEY-----\n"
