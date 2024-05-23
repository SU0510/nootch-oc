//
//  onChangeDebounced.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import SwiftUI

struct DebouncedOnChangeModifier<Value: Equatable>: ViewModifier {
    @State private var debouncedValue: Value
    let value: Value
    let delay: TimeInterval
    let action: (Value) -> Void
    @State private var workItem: DispatchWorkItem?

    init(value: Value, delay: TimeInterval = 0.5, action: @escaping (Value) -> Void) {
        self.value = value
        self.delay = delay
        self.action = action
        _debouncedValue = State(initialValue: value)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                workItem?.cancel() // Cancel the existing work item if it exists
                let newWorkItem = DispatchWorkItem { [self] in
                    self.action(newValue)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
                workItem = newWorkItem // Store the new work item
            }
    }
}

extension View {
    func onChangeDebounced<Value: Equatable>(
        of value: Value,
        delay: TimeInterval = 0.5,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        modifier(DebouncedOnChangeModifier(value: value, delay: delay, action: action))
    }
}
