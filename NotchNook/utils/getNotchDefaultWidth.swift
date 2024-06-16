//
//  getNotchDefaultWidth.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation

func getNotchDefaultWidth() -> Double {
    let sizes: [[String]:Double] = [
        ["Mac15,6", "Mac15,8", "Mac15,10", "Mac15,3"] : 184, // 29
        ["MacBookPro18,1", "MacBookPro18,2", "Mac14,6", "Mac14,10", "Mac15,7", "Mac15,9", "Mac15,11"] : 184, // 30
        ["MacBookPro18,3", "MacBookPro18,4", "Mac14,5", "Mac14,9"] : 184 // 32
    ]
    let model = getMacBookModel() ?? "Mac14,5"
    var width: Double = 184
    for (key, value) in sizes {
        if key.contains(model) { width = value }
    }

    return width
}
