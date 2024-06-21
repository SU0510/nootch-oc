//
//  ReorderWidgetsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

struct ReorderWidgetsView: View {
    @Binding var widgets: [NookWidget]
    @State private var dragSize: CGSize = .zero
    @Default(.mediaWidgetSettings) private var mediaWidgetSettings
    @Default(.mirrorWidgetSettings) private var mirrorWidgetSettings
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @Default(.nookSettings) private var nookSettings
    private let spacing: CGFloat = 8
    
    func moveLeft(_ widget: NookWidget) {  }
    
    var body: some View {
        VStack {
            let usedCells = nookSettings.enabledWidgets.reduce(NookGrid.Point.zero) { $0 + $1.prefs.size.width }
            let totalCells = nookSettings.size.width
            let available = totalCells - usedCells
            
            HStack {
                Text("REMAINING CELLS: \(available.value)")
                Spacer()
                Text("TOTAL CELLS: \(totalCells.value)")
            }
            .padding(.horizontal, 24)
            .font(.system(size: 11, weight: .semibold))
            .opacity(0.5)
            
            ZStack(alignment: .top) {
                HStack(spacing: spacing) {
                    let availableWidth = dragSize.width - (CGFloat(widgets.count - 1) * spacing)
                    let cell = availableWidth / CGFloat(nookSettings.size.width.value)
                    
                    ForEach(Array(widgets.enumerated()), id: \.element) { i, widget in
                        let arrPos = ArrayPosition(total: widgets.count, i: i)
                        ReorderWidgetDragView(
                            widget: widget,
                            moveLeft: arrPos == .middle || arrPos == .last ? { widgets.moveLeft(at: i) } : nil,
                            moveRight: arrPos == .middle || arrPos == .first ? { widgets.moveRight(at: i) } : nil
                        )
                        .frame(width: CGFloat(widget.prefs.size.width.value) * cell)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                }
                .animation(.spring, value: widgets)
                .animation(.spring, value: [
                    mediaWidgetSettings.size.width.value,
                    mirrorWidgetSettings.size.width.value,
                    shortcutsWidgetSettings.size.width.value,
                    calendarWidgetSettings.size.width.value,
                    nookSettings.enabledWidgets.count
                ])
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .measure($dragSize)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: 100, alignment: .top)
            .background { ActualSizeCurrentWallpaperView() }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
    }
}

private struct ReorderWidgetDragView: View {
    @State private var hovering = false
    var widget: NookWidget
    var moveLeft: (() -> ())?
    var moveRight: (() -> ())?
    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: widget.icon).font(.system(size: 16))
            Text(widget.name).font(.system(size: 13, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.selected, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            if hovering {
                HStack {
                    if let moveLeft { CircleButton(icon: "arrowshape.left.fill", bgColor: .white.opacity(0.1), action: moveLeft) }
                    Spacer()
                    if let moveRight { CircleButton(icon: "arrowshape.right.fill", bgColor: .white.opacity(0.1), action: moveRight) }
                }
                .padding(.horizontal, 4)
            }
        }
        .onHover { x in withAnimation(.easeOut(duration: 0.15)) { hovering = x } }
    }
}
