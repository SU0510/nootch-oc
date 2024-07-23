//
//  TrayFilesScrollView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

import SwiftUI

struct TrayFilesScrollView: View {
    @Environment(\.tray) private var tray: Tray

    var files: Set<TrayFile>
    var selectedFiles: Set<TrayFile>
    var selectFile: (_ file: TrayFile?) -> ()

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(files).sorted(by: { $0.addedAt.timeIntervalSince1970 > $1.addedAt.timeIntervalSince1970 })) { file in
                        TrayFileView(file: file, isSelected: selectedFiles.contains(file))
                    }
                }
                .padding(.all, 8)
                .frame(minWidth: geo.size.width, maxHeight: .infinity, alignment: .leading)
                .background(
                    Color
                        .black
                        .opacity(0.001)
                        .onTapGesture {
                            selectFile(nil)
                            tray.isEditing = false
                        }
                )
            }
        }
    }
}
