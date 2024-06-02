//
//  rowlify.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import Foundation

func rowlify<C>(perRow: Int = 2, elements: [C]) -> [[C]] {
    return stride(from: 0, to: elements.count, by: perRow).map {
        Array(elements[$0..<min($0 + perRow, elements.count)])
    }
}
