//
//  ShortcutsWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI
import Settings
import Defaults

struct ShortcutsWidgetSettingsView: View {
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.nookSettings) private var nookSettings
    
    var availableWidth: NookGrid.Point {
        let otherEnabledWidgets = nookSettings.enabledWidgets.filter { $0 != .shortcuts }
        let usedWidth: NookGrid.Point = otherEnabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }
        let freeWidth = nookSettings.size.width - usedWidth
        return freeWidth
    }
    
    var body: some View {
        let widgetW = Int(shortcutsWidgetSettings.size.width.double)
        let cols = widgetW / Int(shortcutsWidgetSettings.shortcutButtonWidth.double)
        VStack {
            Settings.Container(contentWidth: 520.0) {
                
                Settings.Section(title: "Width (in cells):") {
                    SliderPlus(value: $shortcutsWidgetSettings.size.width.double, range: 2...availableWidth.double)
                }
                
                Settings.Section {
                    Text("Columns:").frame(minWidth: 200, alignment: .trailing)
                } content: {
                    
                    let columnsOpts = findMultipliers(widgetW)
                    Picker("", selection: $shortcutsWidgetSettings.shortcutButtonWidth.double) {
                        ForEach(columnsOpts.filter { $0 > 1 }, id: \.self) { num in
                            let myCols = widgetW / num
                            Text("\(myCols) Column\(cols > 1 ? "s" : "")").tag(Double(num))
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()

                    Text("Each column contains 2 rows (2 shortcuts).")
                        .settingDescription()
                        .frame(maxWidth: 300, alignment: .leading)
                }
            }
            
            HStack {
                (Text(Image(systemName: "sparkles")).foregroundStyle(.yellow) + Text(" Shortcuts")).fontWeight(.semibold)
                VStack {
                    Divider()
                }
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Detected").font(.system(size: 13, weight: .medium))
                            .padding(.leading, 4)
                        Spacer()
                        CircleButton(icon: "arrow.clockwise") {
                            _ = ShortcutsManager.shared.fetchShortcuts()
                        }
                    }
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            let notUsingShorts = ShortcutsManager.shared.shortcuts.filter { !shortcutsWidgetSettings.shortcutsToDisplay.contains($0) }
                            ForEach(Array(notUsingShorts), id: \.self) { shortcut in
                                ShortcutItemView(shortcut: shortcut, buttonLabel: "Use") {
                                    shortcutsWidgetSettings.shortcutsToDisplay.append(shortcut)
                                }
                            }
                        }
                        .padding(4)
                    }
                    .panel()
                }
                //                    .frame(height: 250)
                VStack(alignment: .trailing, spacing: 5) {
                    (
                        Text((cols * 2) < shortcutsWidgetSettings.shortcutsToDisplay.count ? "\(cols * 2) visible" : "")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.5)) +
                        Text(" In use").font(.system(size: 13, weight: .medium))
                    )
                    .frame(height: 27)
                    .padding(.trailing, 4)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            if shortcutsWidgetSettings.shortcutsToDisplay.isEmpty {
                                Text("Select some shortcuts")
                                    .frame(maxWidth: .infinity, minHeight: 200)
                                    .opacity(0.5)
                            } else {
                                ForEach(Array(shortcutsWidgetSettings.shortcutsToDisplay.enumerated()), id: \.element) { i, shortcut in
                                    ShortcutItemView(shortcut: shortcut, buttonLabel: "Remove", hidden: i >= (cols * 2)) {
                                        shortcutsWidgetSettings.shortcutsToDisplay = shortcutsWidgetSettings.shortcutsToDisplay.filter { $0 != shortcut }
                                    }
                                }
                            }
                        }
                        .padding(4)
                    }
                    .panel()
                }
            }
            .padding(.horizontal, 30)
            
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: shortcutsWidgetSettings.size.width.double) { _, newValue in
            let columnsOpts = findMultipliers(Int(shortcutsWidgetSettings.size.width.double)).filter { $0 > 1 }
            let shortBtnW = Int(shortcutsWidgetSettings.shortcutButtonWidth.double)
            if !columnsOpts.contains(shortBtnW), let newVal = columnsOpts.closest(to: shortBtnW) {
                withAnimation {
                    shortcutsWidgetSettings.shortcutButtonWidth.double = Double(newVal)
                }
            }
        }
//        .onChange(of: shortcutsWidgetSettings.shortcutButtonWidth) { _, newValue in
//            let availableSteps = (1...(availableWidth / newValue).value)
//                .map { $0 * newValue.value }
//                .filter { $0 <= availableWidth.value }
//            let newVal = availableSteps.closest(to: shortcutsWidgetSettings.size.width.value) ?? newValue.value
//            if shortcutsWidgetSettings.size.width.value != newVal {
//                shortcutsWidgetSettings.size.width.value = newVal
//            }
//        }
    }
    
    func findMultipliers(_ number: Int) -> [Int] {
        var multipliers: [Int] = []
        for i in 1...number {
            if number % i == 0 {
                multipliers.append(i)
            }
        }
        return multipliers
    }
}

private extension View {
    func panel() -> some View {
        self
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.black.opacity(0.03))
                    .blendMode(.plusDarker)
            }
    }
}

struct ShortcutItemView: View {
    var shortcut: String
    var buttonLabel: String
    var hidden: Bool = false
    var buttonAction: () -> ()
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.yellow)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text(shortcut)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if hidden {
                    Text("Hidden, it doesn't fit.")
                        .font(.caption)
                        .opacity(0.5)
                }
            }
            
            Spacer()
            
            Button(buttonLabel, action: buttonAction)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .opacity(hidden ? 0.5 : 1)
    }
}
