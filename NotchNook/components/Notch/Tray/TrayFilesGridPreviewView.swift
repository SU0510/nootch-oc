//
//  TrayFilesGridPreviewView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct TrayFilesGridPreviewView: View {
    var files: [TrayFile]
    
    let iconsSize: CGFloat = 24
    let gridSpacing: CGFloat = 8
    var body: some View {
        if files.count > 0 {
            VStack(spacing: gridSpacing) {
                Group {
                    HStack(spacing: gridSpacing) {
                        TrayFileIconView(file: files[0])
                            .frame(iconsSize)
                        if files.count > 1 {
                            TrayFileIconView(file: files[1])
                                .frame(iconsSize)
                        }
                    }
                    HStack(spacing: gridSpacing) {
                        if files.count > 2 {
                            TrayFileIconView(file: files[2])
                                .frame(iconsSize)
                        }
                        if files.count > 3 {
                            TrayFileIconView(file: files[3])
                                .frame(iconsSize)
                        }
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
