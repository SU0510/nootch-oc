//
//  NookTimersStore.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import SwiftUI
import AppKit

/// Manages user-facing countdown timers for the Timer widget.
/// Distinct from `TimersManager` (which is a generic delay-callback utility).
@Observable
final class NookTimersStore {
    static let shared = NookTimersStore()

    var timers: [TimerEntry] = []
    /// Label of the most recently expired timer — read by LiveActivityView's timerExpired case.
    var lastExpiredLabel: String = ""

    private var tickTimer: Foundation.Timer?
    private let persistenceKey = "nookTimerEntries"

    private init() {
        load()
        startTick()
    }

    // MARK: - Public API

    func add(label: String, totalSeconds: Int) {
        let entry = TimerEntry(label: label, totalSeconds: totalSeconds)
        timers.append(entry)
        start(entry)
    }

    func start(_ entry: TimerEntry) {
        guard entry.state != .expired else { return }
        let remaining = max(entry.remainingSeconds, 0)
        entry.expiresAt = Date().addingTimeInterval(Double(remaining))
        entry.startedAt = Date()
        entry.state = .running
        save()
    }

    func pause(_ entry: TimerEntry) {
        guard entry.state == .running else { return }
        entry.state = .paused
        entry.expiresAt = nil
        save()
    }

    func resume(_ entry: TimerEntry) {
        guard entry.state == .paused else { return }
        start(entry)
    }

    func cancel(_ entry: TimerEntry) {
        timers.removeAll { $0.id == entry.id }
        save()
    }

    func dismissExpired(_ entry: TimerEntry) {
        timers.removeAll { $0.id == entry.id }
        save()
    }

    func removeAll() {
        timers.removeAll()
        save()
    }

    // MARK: - Tick

    private func startTick() {
        tickTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    private func tick() {
        var dirty = false
        for entry in timers where entry.state == .running {
            if let expiresAt = entry.expiresAt {
                let remaining = expiresAt.timeIntervalSinceNow
                if remaining <= 0 {
                    entry.remainingSeconds = 0
                    expire(entry)
                    dirty = true
                } else {
                    let newRemaining = Int(ceil(remaining))
                    if newRemaining != entry.remainingSeconds {
                        entry.remainingSeconds = newRemaining
                        dirty = true
                    }
                }
            }
        }
        if dirty { save() }
    }

    private func expire(_ entry: TimerEntry) {
        entry.state = .expired
        entry.expiresAt = nil
        playSound()
        fireTimerExpiredLA(label: entry.label)
    }

    // MARK: - Live Activity (timer expiry notification)

    private func fireTimerExpiredLA(label: String) {
        lastExpiredLabel = label.isEmpty ? "" : "\"\(label)\" ended"
        // Cancel any pending dismiss so it restarts fresh if multiple timers fire quickly
        TimersManager.shared.removeTimer("TimerExpiredLADismiss")
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.timerExpired)
        TimersManager.shared.addTimer("TimerExpiredLADismiss", delay: 4) { _ in
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.timerExpired)
        }
    }

    // MARK: - Sound

    private func playSound() {
        NSSound(named: NSSound.Name("Glass"))?.play()
    }

    // MARK: - Persistence (UserDefaults JSON)

    private func save() {
        guard let data = try? JSONEncoder().encode(timers.map { SnapshotEntry(from: $0) }) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let snapshots = try? JSONDecoder().decode([SnapshotEntry].self, from: data)
        else { return }

        let now = Date()
        timers = snapshots.map { snap in
            let entry = TimerEntry(id: snap.id, label: snap.label, totalSeconds: snap.totalSeconds)
            entry.remainingSeconds = snap.remainingSeconds
            entry.state = snap.state
            entry.startedAt = snap.startedAt
            entry.expiresAt = snap.expiresAt

            // Rehydrate: if was running, recompute remainingSeconds from wall-clock expiresAt
            if snap.state == .running, let expiresAt = snap.expiresAt {
                let remaining = expiresAt.timeIntervalSince(now)
                if remaining <= 0 {
                    entry.remainingSeconds = 0
                    entry.state = .expired
                    entry.expiresAt = nil
                } else {
                    entry.remainingSeconds = Int(ceil(remaining))
                }
            }

            return entry
        }
    }

    // Plain Codable snapshot (TimerEntry is @Observable, not directly Codable for arrays)
    private struct SnapshotEntry: Codable {
        let id: UUID
        let label: String
        let totalSeconds: Int
        let remainingSeconds: Int
        let state: TimerEntry.State
        let startedAt: Date?
        let expiresAt: Date?

        init(from entry: TimerEntry) {
            id = entry.id
            label = entry.label
            totalSeconds = entry.totalSeconds
            remainingSeconds = entry.remainingSeconds
            state = entry.state
            startedAt = entry.startedAt
            expiresAt = entry.expiresAt
        }
    }
}
