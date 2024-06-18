//
//  MediaLiveAcitivitySettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Settings
import Defaults

struct MediaLiveAcitivitySettingsView: View {
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    var body: some View {
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: "Album corner radius:") {
                SliderPlus(value: $mediaLiveActivitySettings.albumCornerRadius, range: 5...16)
            }
            Settings.Section(title: "") {
                Toggle("Colored Spectograph", isOn: $mediaLiveActivitySettings.coloredSpectograph)
                Text("If enabled, the audio spectograph will take the color of the current playing album, otherwise, it'll be white.")
                    .settingDescription()
                    .frame(width: 400, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
