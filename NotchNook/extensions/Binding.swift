//
//  Binding.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

extension Binding where Value == Bool {
    static func setMembership<T: Hashable>(of member: T, in set: Binding<Set<T>>) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                set.wrappedValue.contains(member)
            },
            set: { newValue in
                if newValue {
                    set.wrappedValue.insert(member)
                } else {
                    set.wrappedValue.remove(member)
                }
            }
        )
    }
}

extension Binding where Value == Bool {
    static func setMembershipArr<T: Hashable>(of member: T, in arr: Binding<[T]>) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                arr.wrappedValue.contains(member)
            },
            set: { newValue in
                if newValue {
                    arr.wrappedValue.append(member)
                } else {
                    arr.wrappedValue = arr.wrappedValue.filter { $0 != member }
                }
            }
        )
    }
}
