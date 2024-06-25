//
//  TrayFile.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI

@Observable
class TrayFile: Equatable, Hashable, Identifiable {
    static func == (lhs: TrayFile, rhs: TrayFile) -> Bool {
        lhs.url.absoluteString == rhs.url.absoluteString
    }
    
    var id: String {
        self.url.absoluteString
    }
    var image: Image
    var rawFileImage: Image?
    var url: URL
    var addedAt: Date
    
    var name: String { self.url.lastPathComponent }
    
    var nameTruncated: String { truncateFileName(self.name, maxLength: 16) }
    
    init(url: URL) {
        self.image = iconForFile(at: url)
        self.url = url
        self.addedAt = Date()
        self.addedAt = Date()
        self.rawFileImage = loadImgFromURL(url)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @ViewBuilder func iconView() -> some View {
        (self.rawFileImage ?? self.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background { if url.isImg { Color.white } }
            .overlay {
                if url.isImg {
                    Rectangle().stroke(.white, style: .init(lineWidth: 2)).shadow(color: .black.opacity(0.5), radius: 1)
                }
            }
    }
    
}
