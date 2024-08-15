//
//  Set+Extensions.swift
//  NotchNook
//
//  Created by Lori Montenegro on 26/07/24.
//

import Foundation

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}
