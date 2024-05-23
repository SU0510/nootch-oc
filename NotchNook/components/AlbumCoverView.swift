//
//  AlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct AlbumCoverView: View, Equatable {
    var artwork: NSImage?
    var cornerRadius: Double
    
    var body: some View {
        Button {
            NSWorkspace.shared.open(appleMusicURL)
        } label: {
            ZStack {
                Group {
                    if let artwork, artwork.isValid {
                        Image(nsImage: artwork)
                            .antialiased(true)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .id(artwork)
                        
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
                .transition(.scaleAndBlur)
            }
            .aspectRatio(1/1, contentMode: .fit)
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(ShrinkOnClick(minSize: 0.925))
        .transition(.scaleAndBlur)
    }
}
