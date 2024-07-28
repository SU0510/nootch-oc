//
//  NoMediaAppsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct NoMediaAppsView: View {
    var body: some View {
        VStack {
            Text("No app seems to be running").font(.system(size: 11, weight: .medium)).opacity(0.75)
            Text("Wanna open one?").font(.system(size: 13, weight: .semibold))
            
//            HStack {
//                ForEach(MediaAppMeta.allCases, id: \.rawValue) { mediaAppMeta in
//                    if 
//                        MediaPlayer.shared.installedApps.contains(mediaAppMeta),
//                            let icon = iconForApp(bundleID: mediaAppMeta.bundleID)
//                    {
//                        Button {
//                            openApp(mediaAppMeta.bundleID)
//                        } label: {
//                            Image(nsImage: icon)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(40)
//                        }
//                        .buttonStyle(ShrinkOnClick())
//                    }
//                }
//            }
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .transition(.scaleAndBlur(anchor: .topTrailing))
    }
}

