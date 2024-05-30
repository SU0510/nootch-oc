//
//  DropAreaTargetView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import AppKit

struct DropAreaTargetView: View {
    var action: DropAction
    var hovered: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            action.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(.blue)
            Text(action.label).fontWeight(.medium).opacity(0.75)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.blue.opacity(hovered ? 0.4 : 0.25), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.easeOut(duration: 0.2), value: hovered)
    }
    
//    private func shareFile() {
//        let sharingPicker = NSSharingServicePicker(items: [filePath])
//        sharingPicker.delegate = context.coordinator
//        sharingPicker.show(relativeTo: .zero, of: NSApp.keyWindow!, preferredEdge: .minY)
//    }
}

//extension DropAreaTargetView {
//    class Coordinator: NSObject, NSSharingServicePickerDelegate {
//        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
//            // Here you can modify available sharing services.
//            return proposedServices
//        }
//        
//        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
//            // Handle when a specific service is selected
//        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//}
