//
//  NotesWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import Settings
import Defaults

struct NotesWidgetSettingsView: View {
    
    @Default(.notesWidgetSettings) private var notesWidgetSettings
    @Default(.nookSettings) private var nookSettings
    
    var body: some View {
        let contentMaxW: Double = 300
        
        Settings.Container(contentWidth: 520.0) {
            Settings.Section {
                Text("Width:").frame(minWidth: 160, alignment: .trailing)
            } content: {
                SliderPlus(value: $notesWidgetSettings.size.width.double, range: 4...16)
                
                Toggle("Show scroll indicator", isOn: $notesWidgetSettings.showScrollIndicator)
                    .padding(.vertical)
                
                Toggle("Code mode", isOn: $notesWidgetSettings.codeMode)
                Text("Enables a per note \"Code Mode\" toggle. It has automatic syntax detection and highlighting.")
                    .optionDescription(contentMaxW)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
