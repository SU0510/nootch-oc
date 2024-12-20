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
        let isGIF = mediaLiveActivitySettings.effect == .gif
        
        Settings.Container(contentWidth: 520.0, minimumLabelWidth: 200) {
            
            // General settings
            
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
            
            // Non-GIF settings
            
            Settings.Section(title: isGIF ? "" : "Colored effects:", verticalAlignment: .top) {
                if !isGIF {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("", isOn: $mediaLiveActivitySettings.isAutomaticallyColored)
                        Text("If enabled, effects will take the color of the current playing album, otherwise, it'll be white.")
                            .optionDescription(contentMaxW)
                    }
                    .padding(.leading, 8)
                }
            }
            
            // GIF settings
            
            Settings.Section(title: isGIF ? String(localized: "GIF Selection:") : "") {
                if isGIF {
                    HStack(spacing: 8) {
                        Picker("", selection: $mediaLiveActivitySettings.selectedGIF) {
                            ForEach(PredefinedGIF.allCases, id: \.self) { gif in
                                Text(gif.name)
                                    .tag(gif)
                            }
                        }
                        .onChange(of: mediaLiveActivitySettings.selectedGIF) {
                            FileManager.default.removeCustomGIF()
                            mediaLiveActivitySettings.customGifURL = nil
                        }
                        .labelsHidden()
                        .fixedSize()
                        
                        Button("Choose File...") {
                            selectGIFFile()
                        }
                        .fixedSize()
                        
                        if mediaLiveActivitySettings.customGifURL != nil {
                            Button("Clear Custom") {
                                FileManager.default.removeCustomGIF()
                                mediaLiveActivitySettings.customGifURL = nil
                            }
                            .fixedSize()
                        }
                    }
                    .animation(.default, value: mediaLiveActivitySettings.effect)
                    .frame(width: 300, alignment: .leading)
                }
            }
            
            Settings.Section(title: isGIF ? String(localized: "Vertical offset:") : "") {
                if isGIF {
                    HStack {
                        SliderPlusNegative(value: $mediaLiveActivitySettings.gifVerticalOffset, range: -16...16, step: 1)
                            .frame(maxWidth: 200)
                        let num = mediaLiveActivitySettings.gifVerticalOffset
                        Text("\(num > 0 ? "+" : "")\(Int(num))")
                    }
                }
            }
            
            Settings.Section(title: isGIF ? String(localized: "Horizontal offset:") : "") {
                if isGIF {
                    HStack {
                        SliderPlusNegative(value: $mediaLiveActivitySettings.gifHorizontalOffset, range: -208...24, step: 2)
                            .frame(maxWidth: 200)
                        let num = mediaLiveActivitySettings.gifHorizontalOffset
                        Text("\(num > 0 ? "+" : "")\(Int(num))")
                    }
                }
            }
            
            Settings.Section(title: isGIF ? String(localized: "GIF Scale:") : "") {
                if isGIF {
                    HStack {
                        Slider(value: $mediaLiveActivitySettings.gifScale, in: 0.5...2.0, step: 0.1)
                            .frame(maxWidth: 200)
                        Text("\(mediaLiveActivitySettings.gifScale, specifier: "%.1f")x")
                    }
                    .padding(.bottom, 10)
                }
            }
            
            Settings.Section(title: isGIF ? String(localized: "GIF Quality:") : "") {
                if isGIF {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("", selection: $mediaLiveActivitySettings.gifScalingQuality) {
                            ForEach(GIFScalingQuality.allCases, id: \.self) { quality in
                                VStack(alignment: .leading) {
                                    Text(quality.rawValue)
                                    Text(quality.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(quality)
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                    .padding(.bottom, 10)
                }
            }
            
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func selectGIFFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.gif]
        
        panel.beginSheetModal(for: NSApp.keyWindow!) { response in
            if response == .OK {
                guard let sourceURL = panel.url else { return }
                do {
                    try FileManager.default.saveCustomGIF(from: sourceURL)
                    if let customGifURL = FileManager.default.customGifURL {
                        mediaLiveActivitySettings.customGifURL = customGifURL
                    }
                } catch {
                    print("Error saving GIF: \(error.localizedDescription)")
                }
            }
        }
    }
    
}
