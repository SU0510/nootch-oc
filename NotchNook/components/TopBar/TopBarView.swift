//
//  TopBarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TopBarView: View {
    let defaultNotchHeight: CGFloat
    let liveActionWidth: CGFloat = 35
    var scaleDown: Double = 1
    var ns: Namespace.ID
    var body: some View {
        HStack(spacing: 0) {
            
            Group {
                switch NotchNook.shared.mode {
                case .closed:
                    let la = NotchNook.shared.activeLiveActions
                    if !la.isEmpty {
                        HStack {
                            if la.contains(.media) {
                                MiniAlbumCoverView(ns: ns)
                            } else if la.contains(.box) {
                                ShelfIconView()
                            }
                        }
                        .frame(width: liveActionWidth)
                    }
                case .dragging: EmptyView()
                case .nook, .shelf: TopBarTabsView()
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(scaleDown, anchor: .trailing)
            .transition(.scaleAndBlur(anchor: .trailing))
            
            Spacer()
                .frame(width: NotchShape.defaultNotchWidth).fixedSize(horizontal: true, vertical: false)
                .transition(.identity)
            
            Group {
                switch NotchNook.shared.mode {
                case .closed:
                    let la = NotchNook.shared.activeLiveActions
                    if !la.isEmpty {
                        HStack {
                            if la.contains(.box) {
                                ShelfFilesCountView()
                            } else if la.contains(.media) {
                                AudioWavesView()
                            }
                        }
                        .frame(width: liveActionWidth)
                    }
                case .dragging: EmptyView()
                case .nook, .shelf: MiniPlayerView()
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(scaleDown, anchor: .leading)
            .transition(.scaleAndBlur(anchor: .leading))
            
        }
        .frame(height: defaultNotchHeight)
        .fixedSize(horizontal: false, vertical: true)
        .zIndex(1)
    }
}
