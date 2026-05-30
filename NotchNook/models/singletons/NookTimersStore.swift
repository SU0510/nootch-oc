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
    /// FIFO queue of formatted labels for expired timers waiting to be displayed.
    /// Each entry gets 4 s on screen before being popped; the next entry then takes over.
    private(set) var expiredLabelQueue: [String] = []
    /// Current label displayed by LiveActivityView — the front of the queue, or "" when empty.
    var currentExpiredLabel: String { expiredLabelQueue.first ?? "" }

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
        let formatted = label.isEmpty ? "Timer ended" : "\"\(label)\" ended"
        let wasEmpty = expiredLabelQueue.isEmpty
        expiredLabelQueue.append(formatted)

        if wasEmpty {
            // Nothing was showing — insert the LA and kick off the first dismiss cycle.
            // tick() runs on RunLoop.main so @MainActor methods are safe here.
            MainActor.assumeIsolated { ActiveLiveActivitiesManager.shared.insertSync(.timerExpired) }
            scheduleNextDismiss()
        }
        // If the queue already had entries the current dismiss timer will naturally pop
        // the front and re-schedule for the newly appended entry — no extra action needed.
    }

    /// Pop the front of the queue and either show the next label or remove the LA.
    /// Must always be called from the main thread (dismiss timer fires on RunLoop.main).
    private func popAndAdvance() {
        guard !expiredLabelQueue.isEmpty else { return }
        expiredLabelQueue.removeFirst()
        if expiredLabelQueue.isEmpty {
            MainActor.assumeIsolated { ActiveLiveActivitiesManager.shared.removeSync(.timerExpired) }
        } else {
            // Another label is waiting — keep the LA up and restart the 4s window.
            scheduleNextDismiss()
        }
    }

    /// Schedule (or replace) the dismiss timer on the main RunLoop with .common mode
    /// so it fires even while the user interacts with a modal sheet or scroll view.
    private func scheduleNextDismiss() {
        let dismissTimer = Timer(timeInterval: 4, repeats: false) { [weak self] _ in
            self?.popAndAdvance()
        }
        RunLoop.main.add(dismissTimer, forMode: .common)
        TimersManager.shared.replaceMainThreadTimer("TimerExpiredLADismiss", timer: dismissTimer)
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
