//
//  TrayFilesScrollView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct TrayFilesScrollView: View {
    @Environment(\.tray) private var tray: Tray

    var files: [TrayFile]
    var selectedFiles: [TrayFile]
    var selectFile: (_ file: TrayFile?) -> ()

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tray.trayItems, id: \.id) { item in
                        switch item {
                        case .single(let file):
                            TrayFileView(file: file, isSelected: selectedFiles.contains(file))
                        case .stack(let id, let stackFiles, let name):
                            TrayStackView(stackID: id, files: stackFiles, name: name)
                        }
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
                            tray.rename()
                        }
                )
            }
        }
    }
}
