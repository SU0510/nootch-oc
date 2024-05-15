//
//  ShelfView.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import SwiftUI

struct ShelfView: View {
    static let id = "sheld"
    var hovered: Bool
    var filesURLs: [URL]
    var full: Bool
    var body: some View {
        HStack {
            if filesURLs.count > 0 {
                ForEach(filesURLs, id: \.self.absoluteString) { url in
                    ShelfFileView(image: iconForFile(at: url), name: truncateFileName(url.lastPathComponent, maxLength: 16))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text("Box").fontWeight(.medium)
                }
                .foregroundStyle(hovered ? Color.blue : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(0.5)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: full ? 32 : 28, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: full ? 32 : 28, style: .continuous).stroke((hovered ? Color.blue : .white).opacity(hovered ? 0.5 : 0.1), style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 12]))
        }
        .animation(.easeOut(duration: 0.2), value: hovered)
    }
}

struct ShelfFileView: View, Equatable {
    var image: Image
    var name: String
    var body: some View {
        VStack(spacing: 2) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
            
            Text(name).font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 56)
                .multilineTextAlignment(.center)
        }
        .transition(.scaleAndBlur)
    }
}
