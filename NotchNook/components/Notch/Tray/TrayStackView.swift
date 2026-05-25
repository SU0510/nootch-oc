//
//  TrayStackView.swift
//  NotchNook
//
//  Renders a collapsed stack chip for files that share a stackID.
//  Tapping the chip opens a popover listing all files individually;
//  each file in the popover is independently draggable.
//  Dragging the chip itself drags all files in the stack.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrayStackView: View {

    let stackID: UUID
    let files: [TrayFile]
    let name: String

    @State private var isExpanded = false
    @State private var isHovering = false

    @Environment(\.tray) private var tray

    // The top file provides the "face" icon of the stack chip.
    private var topFile: TrayFile? { files.first }

    var body: some View {
        ZStack {
            // Drag layer — dragging the chip drags ALL files in the stack.
            FileDraggableView(
                onSelect: {
                    doAfter(0.04) { isExpanded.toggle() }
                },
                onDropCompleted: { didMove in
                    guard didMove else { return }
                    files.forEach { tray.removeFile($0) }
                },
                selectedURLs: files.map(\.url)
            ) {
                stackDragPreview
            }

            // Visual chip sits on top, hit-testing disabled so FileDraggableView handles mouse.
            chipBody
                .allowsHitTesting(false)
        }
        .frame(width: 60)
        .overlay(alignment: .topTrailing) {
            removeButton
                .zIndex(1)
                .allowsHitTesting(true)
        }
        .background(
            Color.nonShockingWhite.opacity(isExpanded ? 0.12 : 0),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .transition(.scaleAndBlur)
        .popover(isPresented: $isExpanded, arrowEdge: .bottom) {
            stackPopover
        }
        .onHover { x in
            withAnimation(.smooth(duration: 0.3, extraBounce: 0.15)) { isHovering = x }
        }
    }

    // MARK: - Chip face

    private var chipBody: some View {
        VStack(spacing: 2) {
            ZStack {
                // Shadow layer — second file icon peeking behind, slightly offset.
                if files.count >= 2 {
                    TrayFileIconView(file: files[1])
                        .frame(width: 34, height: 34)
                        .opacity(0.55)
                        .offset(x: 3, y: 3)
                }
                // Front icon.
                if let top = topFile {
                    TrayFileIconView(file: top)
                        .frame(width: 40, height: 40)
                }
            }
            .frame(width: 44, height: 44)
            // Count badge.
            .overlay(alignment: .bottomTrailing) {
                Text("\(files.count)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(.blue, in: Circle())
                    .offset(x: 2, y: 2)
            }

            Text(name)
                .font(.caption)
                .foregroundStyle(.nonShockingWhite)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 56, alignment: .center)
        }
        .padding(6)
        .frame(maxHeight: .infinity, alignment: .top)
        .foregroundStyle(.nonShockingWhite)
    }

    // MARK: - Remove button

    private var removeButton: some View {
        VStack {
            if isHovering {
                Button {
                    withAnimation(.smooth) { files.forEach { tray.removeFile($0) } }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(ShrinkOnClick())
                .transition(.scale)
                .offset(x: 2, y: -2)
            }
        }
        .frame(20)
        .contentShape(Circle())
    }

    // MARK: - Drag preview (used while dragging the whole stack)

    private var stackDragPreview: some View {
        ZStack(alignment: .bottomTrailing) {
            if let top = topFile {
                VStack(spacing: 2) {
                    TrayFileIconView(file: top)
                        .frame(width: 42, height: 42)
                    Text(name)
                        .font(.caption)
                        .frame(width: 56, alignment: .center)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue))
                }
                .foregroundStyle(.nonShockingWhite)
                .padding(6)
            }
            Text("+\(files.count - 1)")
                .font(.system(size: 12, weight: .semibold))
                .frame(24)
                .background(.bar, in: Circle())
                .padding(.all, 4)
        }
    }

    // MARK: - Expanded popover

    private var stackPopover: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(files) { file in
                        TrayStackFileRowView(file: file, onRemove: {
                            tray.removeFile(file)
                            // If this was the last file in the stack, dismiss the popover.
                            if files.count <= 1 { isExpanded = false }
                        })
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .frame(minWidth: 200, maxWidth: 240)
    }
}

// MARK: - Individual row inside the expanded popover

/// A single file row inside the TrayStackView popover.
/// Shows the file icon + name, supports independent drag-out, and has a remove button.
private struct TrayStackFileRowView: View {

    let file: TrayFile
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        ZStack {
            // Drag layer for the individual file.
            FileDraggableView(
                onSelect: { /* row tap: no-op in popover context */ },
                onDropCompleted: { didMove in
                    if didMove { onRemove() }
                },
                selectedURLs: [file.url]
            ) {
                // Lightweight drag preview: just the icon.
                TrayFileIconView(file: file)
                    .frame(width: 32, height: 32)
            }

            // Row visual.
            HStack(spacing: 8) {
                TrayFileIconView(file: file)
                    .frame(width: 24, height: 24)
                Text(file.nameTruncated)
                    .font(.caption)
                    .foregroundStyle(.nonShockingWhite)
                    .lineLimit(1)
                Spacer()
                if isHovering {
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(ShrinkOnClick())
                    .transition(.scale)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .allowsHitTesting(false)
        }
        .background(
            Color.nonShockingWhite.opacity(isHovering ? 0.08 : 0),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .onHover { x in
            withAnimation(.smooth(duration: 0.2)) { isHovering = x }
        }
        .frame(height: 32)
    }
}
