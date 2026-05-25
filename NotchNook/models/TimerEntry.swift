//
//  TimerEntry.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import Foundation

@Observable
final class TimerEntry: Identifiable, Codable {
    let id: UUID
    var label: String
    var totalSeconds: Int
    var remainingSeconds: Int
    var state: State
    var startedAt: Date?
    var expiresAt: Date?

    enum State: String, Codable {
        case running, paused, expired
    }

    init(id: UUID = UUID(), label: String, totalSeconds: Int) {
        self.id = id
        self.label = label
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds
        self.state = .paused
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, label, totalSeconds, remainingSeconds, state, startedAt, expiresAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        totalSeconds = try c.decode(Int.self, forKey: .totalSeconds)
        remainingSeconds = try c.decode(Int.self, forKey: .remainingSeconds)
        state = try c.decode(State.self, forKey: .state)
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt)
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(label, forKey: .label)
        try c.encode(totalSeconds, forKey: .totalSeconds)
        try c.encode(remainingSeconds, forKey: .remainingSeconds)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(startedAt, forKey: .startedAt)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt)
    }
}
