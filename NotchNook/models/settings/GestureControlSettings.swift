//
//  GestureControlSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation

struct GestureControlSettings: Preferences {
    var allowGestures = true
    var controlMedia = true
    var controlOpenState = true
    var invertMediaGestures = false

    init(
        allowGestures: Bool = true,
        controlMedia: Bool = true,
        controlOpenState: Bool = true,
        invertMediaGestures: Bool = false
    ) {
        self.allowGestures = allowGestures
        self.controlMedia = controlMedia
        self.controlOpenState = controlOpenState
        self.invertMediaGestures = invertMediaGestures
    }

    // Synthesized Codable is all-or-nothing: a single missing key makes the whole
    // decode throw, so any legacy/partial stored value collapses — and depending on
    // the Defaults version that can surface as every gesture toggle coming up
    // unchecked. Decode each field with decodeIfPresent so a missing key falls back
    // to its default (the three controls ON, invert OFF) and decode never throws.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GestureControlSettings()
        allowGestures = try c.decodeIfPresent(Bool.self, forKey: .allowGestures) ?? d.allowGestures
        controlMedia = try c.decodeIfPresent(Bool.self, forKey: .controlMedia) ?? d.controlMedia
        controlOpenState = try c.decodeIfPresent(Bool.self, forKey: .controlOpenState) ?? d.controlOpenState
        invertMediaGestures = try c.decodeIfPresent(Bool.self, forKey: .invertMediaGestures) ?? d.invertMediaGestures
    }
}
