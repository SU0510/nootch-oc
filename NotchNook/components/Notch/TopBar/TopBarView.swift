//
//  TopBarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TopBarView: View {
    let liveActionWidth: CGFloat = 35
    var scale: Double = 1
    var panPadding: EdgeInsets
    var hide: Bool
    var ns: Namespace.ID
    @Environment(\.notchHeight) private var notchHeight
    @Environment(\.screenID) private var screenID
    var body: some View {
        let mode = NotchNook.shared.mode[screenID]!
        let la = NotchNook.shared.activeLiveActions
        HStack(spacing: 0) {
            
            if !hide {
                Group {
                    switch mode {
                    case .closed:
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
                .scaleEffect(scale, anchor: .topTrailing)
                .transition(NotchView.defaultTransition(anchor: .trailing, delay: 0.075))
            }
            
            NotchSpacerView()
            
            if !hide {
                Group {
                    switch mode {
                    case .closed:
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
                    case .nook, .shelf: HStack { MiniPlayerView() }
                    }
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(scale, anchor: .topLeading)
                .transition(NotchView.defaultTransition(anchor: .leading, delay: 0.075))
            }
            
        }
        .background {
            HStack(spacing: 0) {
                let showArrows = panPadding.bottom < (NotchView.maxHPanDrag / 3)
                Group {
                    switch mode {
                    case .closed:
                        let la = NotchNook.shared.activeLiveActions
                        if la.contains(.media) {
                            ArrowForPanningView(x:  !showArrows ? 0 : -panPadding.leading, right: false)
                                .frame(maxWidth: liveActionWidth, maxHeight: .infinity, alignment: .leading)
                        }
                    case .dragging, .nook, .shelf: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(scale, anchor: .trailing)
                .transition(.scaleAndBlur(anchor: .trailing))
                
                Spacer()
                    .frame(width: NotchShape.defaultNotchWidth).fixedSize(horizontal: true, vertical: false)
                    .transition(.identity)
                
                Group {
                    switch mode {
                    case .closed:
                        if la.contains(.media) {
                            ArrowForPanningView(x: !showArrows ? 0 : panPadding.trailing, right: true)
                                .frame(maxWidth: liveActionWidth, maxHeight: .infinity, alignment: .trailing)
                        }
                    case .nook, .shelf, .dragging: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(scale, anchor: .leading)
                .transition(.scaleAndBlur(anchor: .leading))
            }
        }
        .frame(height: notchHeight < NotchShape.usualNotchHeight / 2 && (mode != .closed || !la.isEmpty) ? NotchShape.usualNotchHeight : notchHeight)
        .fixedSize(horizontal: false, vertical: true)
        .zIndex(1)
    }
}
