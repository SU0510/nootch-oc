//
//  MediaPlayerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct MediaPlayerView: View {
    @State var viewModel = MediaPlayer()
    
    var body: some View {
        VStack {
            if let albumCover = NSImage(named: viewModel.currentMedia.albumCover) {
                Image(nsImage: albumCover)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 300, height: 300)
                    .cornerRadius(10)
            }
            
            Text(viewModel.currentMedia.title)
                .font(.title)
                .padding(.top, 10)
            
            Text(viewModel.currentMedia.artist)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: {
                    viewModel.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.isPlaying ? viewModel.pause() : viewModel.play()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.top, 20)
            .frame(width: 200)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}
