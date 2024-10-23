//
//  RichToolbarButtonView.swift
//  NotchNook
//
//  Created by Lori Montenegro on 10/10/24.
//

import SwiftUI

struct RichToolbarButtonView: View {
    var icon: String
    var tooltip: String
    var action: () -> Void
    var active: Bool
    @State private var hovering = false
    var buttonStyle: ToolbarButtonStyleKind
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
        }
        .help(Text(tooltip))
        .buttonStyle(ToolbarButtonStyle(hovering: hovering, active: active, styleKind: buttonStyle))
        .onHover { hovering = $0 }
    }
}
