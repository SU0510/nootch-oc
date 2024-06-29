//
//  AlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct AlbumCoverView: View {
    var id: String?
    var artwork: NSImage?
    var appIcon: NSImage?
    var cornerRadius: Double
    
    @Environment(\.openApp) private var openApp
    
    var body: some View {
        Button {
            if let bundleID = MediaPlayer.shared.connectedApp?.bundleID {
                openApp(bundleID)
            }
        } label: {
            ZStack {
                Group {
                    if let artwork, artwork.isValid {
                        Image(nsImage: artwork)
                            .interpolation(.high)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .id(id ?? String(artwork.hashValue))
                    } else {
                        Color.selected
                            .overlay {
                                GeometryReader { geo in
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(geo.size * 0.55)
                                        .frame(geo.size)
                                        .foregroundStyle(.white.opacity(0.25))
                                }
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    if let appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .scaledToFit()
                            .shadow(radius: 8, y: 0)
                            .shadow(radius: 12, y: 8)
                            .frame(32)
                            .offset(x: 6, y: 6)
                    }
                }
                .transition(.scaleAndBlur)
            }
            .animation(.bouncySmooth, value: artwork)
            .aspectRatio(1/1, contentMode: .fit)
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(ShrinkOnClick(minSize: 0.925))
        .transition(.scaleAndBlur)
    }
}
