//
//  ShelfFilesScrollView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct ShelfFilesScrollView: View {
    var files: Set<ShelfFile>
    var selectedFiles: Set<ShelfFile>
    var selectFile: (_ file: ShelfFile?) -> ()
    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(files).sorted(by: { $0.addedAt.timeIntervalSince1970 > $1.addedAt.timeIntervalSince1970 })) { file in
                        ShelfFileView(file: file, isSelected: selectedFiles.contains(file))
                    }
                }
                .padding(.all, 8)
                .frame(minWidth: geo.size.width, maxHeight: .infinity, alignment: .leading)
                .background { Color.black.opacity(0.001).onTapGesture { selectFile(nil) } }
            }
        }
    }
}
