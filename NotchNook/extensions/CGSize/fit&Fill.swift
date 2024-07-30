//
//  fit.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/07/24.
//

import Foundation
import SwiftUI

extension CGSize {
    func fit(in size: CGSize) -> CGSize {
        let widthRatio = size.width / self.width
        let heightRatio = size.height / self.height
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: self.width * scale, height: self.height * scale)
    }

    func fill(in size: CGSize) -> CGSize {
        let widthRatio = size.width / self.width
        let heightRatio = size.height / self.height
        let scale = max(widthRatio, heightRatio)
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}
