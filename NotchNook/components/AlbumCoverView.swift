//
//  AlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct AlbumCoverView: View, Identifiable, Equatable {
    static func == (lhs: AlbumCoverView, rhs: AlbumCoverView) -> Bool {
        lhs.id == rhs.id && lhs.cornerRadius == rhs.cornerRadius && lhs.artwork?.isValid == rhs.artwork?.isValid
    }
    
    var id: String
    var artwork: NSImage?
    var cornerRadius: Double
    
    var body: some View {
        ZStack {
            Color.clear
                .overlay {
                    Group {
                        if let artwork, artwork.isValid {
                            Image(nsImage: artwork)
                                .interpolation(.high)
                                .resizable()
                                .scaledToFill()
                        } else {
                            GeometryReader { geo in
                                Image(systemName: "music.note")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(geo.size * 0.55)
                                    .frame(width: geo.size.height, height: geo.size.height)
                                    .foregroundStyle(.nonShockingWhite.opacity(0.25))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .id(id)
                .transition(.scaleAndBlur)
                .aspectRatio(1, contentMode: .fit)
        }
        .animation(.bouncySmooth, value: artwork)
        .aspectRatio(1, contentMode: .fit)
        .transition(.scaleAndBlur)
    }
}
