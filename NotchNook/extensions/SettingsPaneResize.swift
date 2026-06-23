//
//  SettingsPaneResize.swift
//  NotchNook
//
//  Lets WindowsManager make the (otherwise fixed-size) Settings window resizable.
//
//  The `Settings` package hosts each pane in `Settings.PaneHostingController`, an
//  `NSHostingController`. On macOS 13+ its `sizingOptions` defaults to
//  `.standardBounds`, which pins the hosting view's min AND max size to the SwiftUI
//  content's intrinsic size. Combined with the package pinning each pane to the
//  content view's edges at required priority, Auto Layout derives `min == max` for
//  the window — so it stays fixed-size and the resize cursor never appears, even
//  after inserting `.resizable` into the styleMask. Clearing `sizingOptions` removes
//  those constraints so the window can actually be dragged to resize.
//
//  This lives in its own file so we can `import enum Settings.Settings`, which makes
//  the bare name `Settings` resolve unambiguously to the package's enum (it otherwise
//  clashes with the module named `Settings` at use sites in WindowsManager).
//

import AppKit
import enum Settings.Settings

/// Marker protocol so the fix can target the package's generic
/// `PaneHostingController<Content>` without naming its `Content` type parameter.
protocol PaneSizingRelaxable: AnyObject {
    func relaxSizing()
}

extension Settings.PaneHostingController: PaneSizingRelaxable {
    func relaxSizing() {
        // `.intrinsicContentSize` (NOT `[]`): keep giving the hosting view an
        // intrinsic content size so the package's `view.fittingSize` stays valid —
        // it uses that to size the window on every tab switch. Dropping ONLY the
        // `.minSize` / `.maxSize` options removes the hard window min==max lock
        // (which prevented resizing) while preserving the flexible intrinsic size.
        // Clearing sizingOptions entirely makes fittingSize collapse to ~0, which
        // shrinks the window to nothing on the next tab switch.
        sizingOptions = .intrinsicContentSize
    }
}

/// Clear `sizingOptions` on a pane if it's a `PaneHostingController`; no-op otherwise.
func relaxPaneSizing(_ pane: AnyObject) {
    (pane as? PaneSizingRelaxable)?.relaxSizing()
}
