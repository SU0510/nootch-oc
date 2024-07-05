//
//  doAfter.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import Foundation

func doAfter(_ seconds: CGFloat = 0, callback: @escaping () -> Void) {
    return DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        callback()
    }
}
