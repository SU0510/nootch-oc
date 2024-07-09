//
//  GIFView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/07/24.
//

import SwiftUI

struct GIFView: View {
    @State private var url: URL = Bundle.main.url(forResource: "michael", withExtension: "gif")!
    var body: some View {
        QLImage(url: url)
//        GIFViewer(url: $url)
            .scaledToFit()
            .frame(40, .bottomTrailing)
            .padding(.trailing, 2)
    }
}
