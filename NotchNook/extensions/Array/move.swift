//
//  move.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import Foundation

extension Array {
    mutating func move(from oldIndex: Int, to newIndex: Int) {
        guard oldIndex != newIndex,
              startIndex..<endIndex ~= oldIndex,
              startIndex..<endIndex ~= newIndex
        else { return }

        insert(remove(at: oldIndex), at: newIndex)
    }
}

extension Array {
    mutating func moveLeft(at index: Int) {
        guard index > startIndex else { return }
        move(from: index, to: index - 1)
    }

    mutating func moveRight(at index: Int) {
        guard index < endIndex - 1 else { return }
        move(from: index, to: index + 1)
    }
}
