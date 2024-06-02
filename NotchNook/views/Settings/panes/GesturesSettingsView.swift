//
//  GesturesSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/06/24.
//

import SwiftUI
import Defaults

struct GesturesSettingsView: View {
    @Default(.gestureControlSettings) private var gestureControlSettings
    var body: some View {
        Form {
            Section {
                Toggle("Allow gestures when hovering the notch", isOn: $gestureControlSettings.allowGestures)
                
                Toggle(
                    "Open/close notch with vertical gestures",
                    isOn: $gestureControlSettings.controlOpenState
                )
                .disabled(!gestureControlSettings.allowGestures)
                
                Toggle(
                    "Control media with horizontal gestures",
                    isOn: $gestureControlSettings.controlMedia
                )
                .disabled(!gestureControlSettings.allowGestures)
                
                CustomLabeled(
                    title: "Invert media gestures actions",
                    description: "If on, a left swipe will to next song, if off, to the previous one."
                ) {
                    Toggle("", isOn: $gestureControlSettings.invertMediaGestures)
                        .disabled(!gestureControlSettings.allowGestures)
                }
            }
        }
        .scrollDisabled(true)
        .animation(.default, value: gestureControlSettings.allowGestures)
        .formStyle(.grouped)
        .defaultSettingsProps()
    }
}
