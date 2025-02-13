//
//  MultipleSettingsPicker.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI
import Combine

struct MultipleSettingsPicker<El: MetaInfo, PrefsView: View, Preview: View>: View {
    
    var elements: [El]
    
    @Binding var activeElements: [El]
    
    @State private var selectedElement: El
    @State private var contentSize: CGSize = .zero
    
    var disableItem: ((El) -> Bool)?
    
    @ViewBuilder var preview: (_ selectedElement: El) -> Preview
    @ViewBuilder var settings: (_ selectedElement: El) -> PrefsView
    
    init(
        elements: [El],
        activeElements: Binding<Set<El>>,
        disableItem: ((El) -> Bool)? = nil,
        @ViewBuilder preview: @escaping (_ selectedElement: El) -> Preview,
        @ViewBuilder settings: @escaping (_ selectedElement: El) -> PrefsView
    ) {
        self.elements = elements
        self._activeElements = .init(get: {
            Array(activeElements.wrappedValue)
        }, set: { newSet in
            activeElements.wrappedValue = Set(newSet)
        })
        if elements.count > 0 {
            self._selectedElement = .init(initialValue: elements[0])
        }
        self.disableItem = disableItem
        self.preview = preview
        self.settings = settings
        self._selectedElement = .init(initialValue: elements[0])
    }
    
    init(
        elements: [El],
        activeElements: Binding<[El]>,
        disableItem: ((El) -> Bool)? = nil,
        @ViewBuilder preview: @escaping (_ selectedElement: El) -> Preview,
        @ViewBuilder settings: @escaping (_ selectedElement: El) -> PrefsView
    ) {
        self.elements = elements
        self._activeElements = activeElements
        if elements.count > 0 {
            self._selectedElement = .init(initialValue: elements[0])
        }
        self.disableItem = disableItem
        self.preview = preview
        self.settings = settings
        self._selectedElement = .init(initialValue: elements[0])
    }
    
    func selectElement(_ element: El) {
        selectedElement = element
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Vertical List
            ElementsListView(
                elements: elements,
                selectElement: selectElement,
                disableItem: disableItem,
                selectedElement: $selectedElement,
                activeElements: $activeElements
            )
            .frame(width: 300)
            
            // Right side - Preview and Settings
            VStack(spacing: 16) {
                preview(selectedElement)
                settings(selectedElement)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding()
    }
}

private struct ElementsListView<El: MetaInfo>: View {
    
    let elements: [El]
    let selectElement: (El) -> Void
    let disableItem: ((El) -> Bool)?
    
    @Binding var selectedElement: El
    @Binding var activeElements: [El]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(elements.enumerated()), id: \.element) { i, element in
                    MultipleSettingsPickerItemView(
                        element: element,
                        selected: selectedElement == element,
                        select: selectElement,
                        disabled: disableItem?(element) ?? false,
                        isOn: Binding.setMembershipArr(of: element, in: $activeElements)
                    )
                    
                    if i < (elements.count - 1) {
                        HDivider(color: .primary.opacity(0.1))
                    }
                }
            }
            .padding(12)
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.black.opacity(0.03))
                .blendMode(.plusDarker)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}


private struct MultipleSettingsPickerItemView<El: MetaInfo>: View {
    
    var element: El
    var selected: Bool
    var select: (_ element: El) -> ()
    var disabled = false
    
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            select(element)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    Image(systemName: element.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(30)
                        .foregroundStyle(selected ? .blue : .nonShockingWhite)
                        .background(selected ? .nonShockingWhite : .blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(element.name).font(.system(size: 13, weight: .medium))
                        if let description = (element.isImplemented ? element.description : String(localized: "Coming soon...")) {
                            Text(description).font(.system(size: 11)).opacity(0.75)
                        }
                    }
                    .foregroundStyle(selected ? .nonShockingWhite : .primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isOn)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .disabled(disabled)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.blue.opacity(selected ? 0.5 : 0), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(NoBtnStyle())
        .compositingGroup()
        .opacity(element.isImplemented ? 1 : 0.5)
        .disabled(!element.isImplemented)
    }
}

struct HDivider: View {
    let color: Color
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
    }
}
