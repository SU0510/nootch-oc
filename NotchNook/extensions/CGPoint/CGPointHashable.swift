//
//  cgPointHashable.swift
//  winston
//
//  Created by Igor Marcossi on 27/11/23.
//

import Foundation
import CoreGraphics

extension CGPoint: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
  }
}
