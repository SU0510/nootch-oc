//
//  MediaLiveAcitivitySettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Defaults

struct MediaLiveAcitivitySettingsView: View {
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    var body: some View {
        Form {
            CustomLabeled(
                title: "Colored Spectograph",
                description: "If enabled, the audio spectograph will take the color of the current playing album, otherwise, it'll be white."
            ) { Toggle("", isOn: $mediaLiveActivitySettings.coloredSpectograph) }
            
            CustomLabeled(title: "Album Corner Radius") {
                SliderPlus(value: $mediaLiveActivitySettings.albumCornerRadius, range: 5...16)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
