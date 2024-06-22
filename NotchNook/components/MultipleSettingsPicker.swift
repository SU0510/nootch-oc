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
    @Binding var activeElements: Set<El>
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
        self._activeElements = activeElements
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
        self._activeElements = .init(get: {
            Set(activeElements.wrappedValue)
        }, set: { newSet in
            activeElements.wrappedValue = Array(newSet)
        })
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
        VStack(alignment: .center, spacing: 16) {
            preview(selectedElement)
            VStack(alignment: .center, spacing: 0) {
                
                if contentSize != .zero {
                    HorizontalScrollView {
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
                        .frame(width: contentSize.width - 38, alignment: .top)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.black.opacity(0.03))
                                .blendMode(.plusDarker)
                        }
                        .padding(.horizontal, 19)
                }
                
                settings(selectedElement)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .measure($contentSize)
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
                        if let description = (element.isImplemented ? element.description : "Coming soon...") {
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
        .compositingGroup()
        .opacity(element.isImplemented ? 1 : 0.5)
        .disabled(!element.isImplemented)
    }
}








struct HorizontalScrollView<Content: View>: NSViewRepresentable {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = CustomScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.autohidesScrollers = true

        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = hostingView
        
        scrollView.heightAnchor.constraint(equalToConstant: hostingView.intrinsicContentSize.height).isActive = true

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hostingView = nsView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content()
            nsView.needsLayout = true
            nsView.heightAnchor.constraint(equalToConstant: hostingView.intrinsicContentSize.height).isActive = true
        }
    }
}

class CustomScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) {
            var newScrollOrigin: NSPoint
            let currentScrollOrigin = self.contentView.bounds.origin
            let maximumX = self.documentView!.frame.size.width - self.contentView.bounds.size.width
            let delta = event.scrollingDeltaY

            if currentScrollOrigin.x - delta < 0 {
                newScrollOrigin = NSPoint(x: 0, y: currentScrollOrigin.y)
            } else if currentScrollOrigin.x - delta > maximumX {
                newScrollOrigin = NSPoint(x: maximumX, y: currentScrollOrigin.y)
            } else {
                newScrollOrigin = NSPoint(x: currentScrollOrigin.x - delta, y: currentScrollOrigin.y)
            }

            self.contentView.scroll(to: newScrollOrigin)
            self.reflectScrolledClipView(self.contentView)
        } else {
            super.scrollWheel(with: event)
        }
    }
}
