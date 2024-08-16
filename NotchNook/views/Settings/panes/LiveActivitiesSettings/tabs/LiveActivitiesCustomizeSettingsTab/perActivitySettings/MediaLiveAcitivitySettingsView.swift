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
        let contentMaxW: Double = 270
        Settings.Container(contentWidth: 520.0, minimumLabelWidth: 200) {
            
            Settings.Section(title: String(localized: "Album corner radius:"), bottomDivider: true) {
                SliderPlus(value: $mediaLiveActivitySettings.albumCornerRadius, range: 5...16)
            }
            
            Settings.Section(title: String(localized: "Effect type:")) {
                Picker("", selection: $mediaLiveActivitySettings.effect) {
                    ForEach(MediaLiveActivityEffectEnum.allCases) { effect in
                        Text(effect.name).tag(effect)
                    }
                }
                .pickerStyle(.radioGroup)
                .padding(.bottom, 10)
            }
            
            Settings.Section(
                title: mediaLiveActivitySettings.effect == .gif ? String(localized: "GIF vertical offset:") : ""
            ) {
                HStack {
                    Slider(value: $mediaLiveActivitySettings.gifOffset, in: -16...16, step: 1)
                        .frame(maxWidth: 200)
                    let num = mediaLiveActivitySettings.gifOffset
                    Text("\(num > 0 ? "+" : "")\(Int(num))")
                }
                .opacity(mediaLiveActivitySettings.effect == .gif ? 1 : 0)
                .animation(.default, value: mediaLiveActivitySettings.effect)
                .padding(.bottom, 20)
            }
            
            Settings.Section(title: "Colored effects:", verticalAlignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("", isOn: $mediaLiveActivitySettings.isAutomaticallyColored)
                    Text("If enabled, effects will take the color of the current playing album, otherwise, it'll be white.")
                        .optionDescription(contentMaxW)
                }
                .padding(.leading, 8)
            }
            
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
}
