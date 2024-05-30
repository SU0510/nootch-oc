//
//  MultipleSettingsPicker.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI

struct MultipleSettingsPicker<El: MetaInfo, PrefsView: View>: View {
    var elements: [El]
    @Binding var activeElements: Set<El>
    @Binding var selectedElement: El?
    var disableItem: ((El) -> Bool)?
    @ViewBuilder var settings: () -> PrefsView
    
    init(
        elements: [El],
        activeElements: Binding<Set<El>>,
        selectedElement: Binding<El?>,
        disableItem: ((El) -> Bool)? = nil,
        @ViewBuilder settings: @escaping () -> PrefsView
    ) {
        self.elements = elements
        self._activeElements = activeElements
        self._selectedElement = selectedElement
        self.disableItem = disableItem
        self.settings = settings
    }
    
    init(
        elements: [El],
        activeElements: Binding<[El]>,
        selectedElement: Binding<El?>,
        disableItem: ((El) -> Bool)? = nil,
        @ViewBuilder settings: @escaping () -> PrefsView
    ) {
        self.elements = elements
        self._activeElements = .init(get: {
            Set(activeElements.wrappedValue)
        }, set: { newSet in
            activeElements.wrappedValue = Array(newSet)
        })
        self._selectedElement = selectedElement
        self.disableItem = disableItem
        self.settings = settings
    }
    
    func selectElement(_ element: El) {
        selectedElement = element
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 4) {
                    ForEach(Array(elements.enumerated()), id: \.element) { i, element in
                        MultipleSettingsPickerItemView(
                            element: element,
                            selected: selectedElement == element,
                            select: selectElement,
                            isOn: Binding.setMembership(of: element, in: $activeElements),
                            disabled: disableItem?(element) ?? false
                        )
                        
                        if i < (elements.count - 1) {
                            VDivider(color: .primary.opacity(0.1))
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(6)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .background(.secondaryPanel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 19)
            
            settings()
                .scrollDisabled(true)
        }
    }
}


private struct MultipleSettingsPickerItemView<El: MetaInfo>: View {
    var element: El
    var selected: Bool
    var select: (_ element: El) -> ()
    @Binding var isOn: Bool
    var disabled = false
    var body: some View {
        Button {
            select(element)
        } label: {
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: element.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(30)
                        .foregroundStyle(selected ? .blue : .white)
                        .background(selected ? .white : .blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(element.name).font(.system(size: 13, weight: .medium))
                        if let description = element.description {
                            Text(description).font(.system(size: 11)).opacity(0.75)
                        }
                    }
                    .foregroundStyle(selected ? .white : .primary)
                }
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .disabled(disabled)
            }
            .padding(8)
            .background(.blue.opacity(selected ? 0.5 : 0), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(NoBtnStyle())
    }
}
