//
//  ShelfFilesTargetPreviewView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct ShelfFilesTargetPreviewView: View {
    var files: [ShelfFile]
    let iconsSize: CGFloat = 24
    let gridSpacing: CGFloat = 8
    var body: some View {
        if files.count > 0 {
            VStack(spacing: gridSpacing) {
                Group {
                    HStack(spacing: gridSpacing) {
                        files[0].iconView().frame(iconsSize)
                        if files.count > 1 { files[1].iconView().frame(iconsSize) }
                    }
                    HStack(spacing: gridSpacing) {
                        if files.count > 2 { files[2].iconView().frame(iconsSize) }
                        if files.count > 3 { files[3].iconView().frame(iconsSize) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: true, vertical: false)
            .compositingGroup()
            .opacity(0.75)
            .saturation(0)
        }
    }
}
