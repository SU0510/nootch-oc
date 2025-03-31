//
//  ChangelogView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct ChangelogView: View {
    
    @State private var gifPlayer = AVLooperPlayer(url: Bundle.main.url(forResource: "gifs2", withExtension: "mp4")!)
    
    @Environment(\.closeWindow) private var closeWindow
    
    var body: some View {
        VStack(spacing: 32) {
            
            // Top Header
            VStack(spacing: 0) {
                Image(.internalAppIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                
                VStack(spacing: 8) {
                    if let shortVersion = getShortVersion() {
                        (
                            Text("NotchNook ")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            +
                            Text("v\(shortVersion)")
                                .font(.title2)
                                .fontWeight(.ultraLight)
                                .italic()
                                .foregroundStyle(.primary.opacity(0.75))
                        )
                    } else {
                        Text("NotchNook")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text("A cool new feature and a bunch of fixes!")
                        .font(.system(size: 16))
                        .fontWeight(.regular)
                }
            }
            
            VStack(spacing: 25) {
                VideoFeatureView(
                    player: gifPlayer,
                    title: String(localized: "Custom GIFs"),
                    description: String(localized: "Now you can choose your own GIFs for the notch or choose among some cool new options!")
                )
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Other stuff:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            ChangelogItem(icon: "🛠️", text: "Fix media widget and activity for macOS 15.4")
                            Text("Unfortunately we had to reduce the scope for now and it only works for Spotify and Apple Music. Hopefully, we can fix that soon!")
                                .font(.system(size: 12))
                                .fontWeight(.ultraLight)
                                .italic()
                                .foregroundStyle(.primary.opacity(0.75))
                                .padding(.leading, 28)
                        }
                        
                        ChangelogItem(icon: "🛠️", text: "The notch now shows and can be used on hover, even when hidden in fullscreen.")
                        ChangelogItem(icon: "🛠️", text: "Live activities now show even when using the transparent handler functionality.")
                        ChangelogItem(icon: "✨", text: "Improve settings layout for customizing activities and widgets.")
                    }
                }
                .frame(width: 600, alignment: .leading)
            }
            
            // Close Button
            Button {
                closeWindow()
            } label: {
                Text("Cool!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.nonShockingWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(ShrinkOnClick(minSize: 0.95))
            
        }
        .padding(.bottom, 32)
        .padding(.horizontal, 64)
        .overlay(alignment: .topLeading) {
            Image(.leftDecoration)
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 84)
                .padding(.leading, 25)
                .blendMode(.overlay)
                .opacity(0.5)
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 25) {
                Image(.rightDecoration)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 111, height: 72)
                    .padding(.top, 4)
                    .padding(.trailing, 25)
                    .blendMode(.overlay)
                    .opacity(0.5)
                
                Image(.loriSignature)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 111, height: 72)
                    .padding(.trailing, 25)
                    .blendMode(.overlay)
                    .opacity(0.5)
                    .rotationEffect(.degrees(22))
            }
        }
        .background {
            Image(.changelogGradient)
                .resizable()
                .scaledToFill()
                .opacity(0.4)
                .ignoresSafeArea()
        }
        .background {
            VisualEffectViews(material: .popover)
                .ignoresSafeArea()
        }
    }
}

struct ChangelogItem: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.system(size: 18))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 14))
                .fontWeight(.regular)
        }
    }
}
