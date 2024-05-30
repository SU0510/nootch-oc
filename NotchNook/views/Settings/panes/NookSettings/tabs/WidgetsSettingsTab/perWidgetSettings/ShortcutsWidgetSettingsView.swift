//
//  ShortcutsWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI
import Defaults

struct ShortcutsWidgetSettingsView: View {
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.nookSettings) private var nookSettings
    
    var availableWidth: Grid.Point {
        let otherEnabledWidgets = nookSettings.enabledWidgets.filter { $0 != .shortcuts }
        let usedWidth: Grid.Point = otherEnabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }
        let freeWidth = nookSettings.size.width - usedWidth
        return freeWidth
    }
    
    var body: some View {
        Form {
            let btnWidth = shortcutsWidgetSettings.shortcutButtonWidth
            
            CustomLabeled(title: "Widget width", icon: "circle.grid.2x1.fill") {
                let min = btnWidth.double
                let max = ((availableWidth / btnWidth) * btnWidth).double
                if min < max {
                    SliderPlus(value: $shortcutsWidgetSettings.size.width.double, range: min...max, step: btnWidth.double)
                } else {
                    Text("\(Int(max))")
                }
            }
            
            CustomLabeled(title: "Shortcut button width", icon: "button.horizontal.fill") {
                SliderPlus(value: $shortcutsWidgetSettings.shortcutButtonWidth.double, range: 2...6)
            }
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Detected sortcuts").font(.system(size: 13, weight: .medium))
                            .padding(.leading, 4)
                        Spacer()
                        CircleButton(icon: "arrow.clockwise") {
                            ShortcutsManager.shared.fetchShortcuts()
                        }
                    }
                    VStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                let notUsingShorts = ShortcutsManager.shared.shortcuts.filter { !shortcutsWidgetSettings.shortcutsToDisplay.contains($0) }
                                ForEach(Array(notUsingShorts), id: \.self) { shortcut in
                                    ShortcutItemView(shortcut: shortcut, buttonLabel: "Use") {
                                        shortcutsWidgetSettings.shortcutsToDisplay.append(shortcut)
                                    }
                                }
                            }
                        }
                    }
                    .panel()
                }
                .frame(height: 250)
                VStack(alignment: .trailing, spacing: 8) {
                    Text("In use shortcuts").font(.system(size: 13, weight: .medium))
                        .frame(height: 27)
                        .padding(.trailing, 4)
                    VStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                ForEach(Array(shortcutsWidgetSettings.shortcutsToDisplay), id: \.self) { shortcut in
                                    ShortcutItemView(shortcut: shortcut, buttonLabel: "Remove") {
                                        shortcutsWidgetSettings.shortcutsToDisplay = shortcutsWidgetSettings.shortcutsToDisplay.filter { $0 != shortcut }
                                    }
                                }
                            }
                        }
                    }
                    .panel()
                }
                .frame(height: 250)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .onChange(of: shortcutsWidgetSettings.shortcutButtonWidth) { _, newValue in
            let availableSteps = (1...(availableWidth / newValue).value)
                .map { $0 * newValue.value }
                .filter { $0 <= availableWidth.value }
            let newVal = availableSteps.closest(to: shortcutsWidgetSettings.size.width.value) ?? newValue.value
            if shortcutsWidgetSettings.size.width.value != newVal {
                shortcutsWidgetSettings.size.width.value = newVal
            }
        }
    }
}

private extension View {
    func panel() -> some View {
        self
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(.secondaryPanel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ShortcutItemView: View {
    var shortcut: String
    var buttonLabel: String
    var buttonAction: () -> ()
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.yellow)
                .font(.system(size: 16))
            Text(shortcut)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            Button(buttonLabel, action: buttonAction)
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }
}
