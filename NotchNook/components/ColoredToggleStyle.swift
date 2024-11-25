//
//  ColoredToggleStyle.swift
//  NotchNook
//
//  Created by Lori Montenegro on 22/11/24.
//

import SwiftUI

struct ColoredToggleStyle: ToggleStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: 15, height: 15)
                    
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .foregroundColor(.black)
                            .font(.system(size: 9, weight: .bold))
                    }
                }
                
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
