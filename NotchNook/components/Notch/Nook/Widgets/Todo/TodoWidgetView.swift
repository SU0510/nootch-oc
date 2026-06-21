//
//  TodoWidgetView.swift
//  NotchNook
//

import SwiftUI
import SwiftData

struct TodoWidgetView: View {
    var arrayPosition: ArrayPosition
    var internalPadding: Double

    @Environment(\.todoListWidgetSettings) private var prefs
    @Environment(\.modelContext) private var modelContext

    // Fetch all items; sort in-memory after fetch (priority first, then newest first).
    @Query private var allItems: [TodoItem]

    @State private var newTaskText: String = ""

    // Visible items: filtered + sorted (priority first, newest first within each group)
    private var visibleItems: [TodoItem] {
        let archiveCutoff: Date? = {
            guard prefs.autoArchiveCompletedAfterDays > 0 else { return nil }
            let seconds = TimeInterval(prefs.autoArchiveCompletedAfterDays) * 86400
            return Date().addingTimeInterval(-seconds)
        }()

        let filtered = allItems.filter { item in
            if item.isCompleted {
                if let cutoff = archiveCutoff, item.createdAt < cutoff { return false }
                return prefs.showCompleted
            }
            return true
        }

        return filtered.sorted {
            if $0.isPriority != $1.isPriority { return $0.isPriority }
            return $0.createdAt > $1.createdAt
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TodoCreatorView(text: $newTaskText) {
                addItem()
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(visibleItems) { item in
                        TodoRowView(item: item) {
                            deleteItem(item)
                        }
                    }
                }
            }
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: internalPadding)
        // Width from the grid; height fills the Nook band (grid-height + 25pt).
        .frame(width: prefs.size.width.screenPoints, alignment: .leading)
        .frame(maxHeight: .infinity)
    }

    private func addItem() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(title: trimmed)
        modelContext.insert(item)
        try? modelContext.save()
        newTaskText = ""
    }

    private func deleteItem(_ item: TodoItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}
