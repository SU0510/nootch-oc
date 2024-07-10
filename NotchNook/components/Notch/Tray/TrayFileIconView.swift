//
//  TrayFileIconView.swift
//  NotchNook
//
//  Created by Lori Montenegro on 10/07/24.
//

import SwiftUI

struct TrayFileIconView: View {
    
    let file: TrayFile
    
    var body: some View {
        file.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background { if file.isImage { Color.white } }
            .overlay {
                if file.isImage {
                    Rectangle().stroke(.white, style: .init(lineWidth: 2)).shadow(color: .black.opacity(0.5), radius: 1)
                }
            }
            .geometryGroup()
    }
    
}
