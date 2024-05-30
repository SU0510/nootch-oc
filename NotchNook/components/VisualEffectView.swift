//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

import SwiftUI

struct VisualEffectViews: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}
