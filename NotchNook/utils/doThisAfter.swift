//
//  doThisAfter.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import Foundation

func doThisAfter(_ seconds: CGFloat, callback: @escaping () -> Void) {
    return DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        callback()
    }
}
