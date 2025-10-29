//
//  AlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct AlbumCoverView: View, Identifiable, Equatable {
    static func == (lhs: AlbumCoverView, rhs: AlbumCoverView) -> Bool {
        lhs.id == rhs.id && lhs.cornerRadius == rhs.cornerRadius
    }
    
    var id: String
    var artwork: NSImage?
    var cornerRadius: Double
    @State private var displayedArtwork: NSImage?
    
    @State private var rotation: Double = 0
    
    init(id: String, artwork: NSImage?, cornerRadius: Double) {
        self.id = id
        self.artwork = artwork
        self.cornerRadius = cornerRadius
        _displayedArtwork = State(initialValue: artwork?.isValid == true ? artwork : nil)
    }
    
    var body: some View {
        let track = MediaManager.shared.track
        let artworkToShow = artwork?.isValid == true ? artwork : displayedArtwork
        
        ZStack {
            Color.clear
                .overlay {
                    Group {
                        if let artwork = artworkToShow {
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
                .transition(.scaleAndBlur)
                .aspectRatio(1, contentMode: .fit)
        }
        .animation(.bouncySmooth, value: artwork)
        .aspectRatio(1, contentMode: .fit)
        .transition(.scaleAndBlur)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.1)
        .onChange(of: track.album) { oldAlbum, newAlbum in
            if !newAlbum.isEmpty && oldAlbum != newAlbum && !oldAlbum.isEmpty && oldAlbum != "Unknown Album" {
                withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                    rotation += 180
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    rotation = 0
                }
            }
        }
        .onChange(of: artwork) { _, new in
            if new?.isValid == true {
                displayedArtwork = new
            }
        }
    }
}
