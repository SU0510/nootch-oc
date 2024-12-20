//
//  GIFView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/07/24.
//

import SwiftUI

struct GIFView: View {
    
    @Environment(\.mediaLiveActivitySettings) private var settings
    
    let isPlaying: Bool
    
    var currentURL: URL? {
        if let customURL = settings.customGifURL, FileManager.default.fileExists(atPath: customURL.path) {
            return customURL
        }
        return Bundle.main.url(forResource: settings.selectedGIF.rawValue, withExtension: "gif")
    }
    
    var body: some View {
        if let url = currentURL {
            GeometryReader { geometry in
                GIFImageView(url: url, isPlaying: isPlaying)
                    .frame(40)
                    .position(
                        x: geometry.size.width + settings.gifHorizontalOffset,
                        y: geometry.size.height/2 + settings.gifVerticalOffset
                    )
                    .animation(.bouncySmooth, value: settings.gifHorizontalOffset)
                    .animation(.spring(response: 0.2), value: settings.gifVerticalOffset)
            }
        } else {
            EmptyView()
        }
    }
}
