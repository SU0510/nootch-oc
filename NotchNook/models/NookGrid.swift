//
//  NookGrid.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct NookGrid {
    static let point: Int = 50
    
    struct Point: Hashable, Equatable, Codable, Comparable {
        static let zero = Point(0)
        
        var value: Int
        var double: Double {
            get { Double(value) }
            set { self.value = Int(newValue) }
        }
        var screenPoints: Double { Double(self.value * NookGrid.point) }

        init(_ value: Int) {
            self.value = value
        }

        static func < (lhs: Point, rhs: Point) -> Bool {
            return lhs.value < rhs.value
        }

        static func +(lhs: Point, rhs: Point) -> Point {
            return Point(lhs.value + rhs.value)
        }

        static func -(lhs: Point, rhs: Point) -> Point {
            return Point(lhs.value - rhs.value)
        }

        static func *(lhs: Point, rhs: Point) -> Point {
            return Point(lhs.value * rhs.value)
        }

        static func /(lhs: Point, rhs: Point) -> Point {
            guard rhs.value != 0 else {
                fatalError("Division by zero.")
            }
            return Point(lhs.value / rhs.value)
        }
        
        static func +=(lhs: inout Point, rhs: Point) {
            lhs = lhs + rhs
        }

        static func -=(lhs: inout Point, rhs: Point) {
            lhs = lhs - rhs
        }

        static func *=(lhs: inout Point, rhs: Point) {
            lhs = lhs * rhs
        }

        static func /=(lhs: inout Point, rhs: Point) {
            lhs = lhs / rhs
        }
    }
    
    struct Size: Hashable, Equatable, Codable {
        var width: Point
        var height: Point
        
        init(width: Int, height: Int) {
            self.width = Point(width)
            self.height = Point(height)
        }
        
        init(width: Point, height: Point) {
            self.width = width
            self.height = height
        }
        
        var screenPtsCGSize: CGSize { CGSize(width: self.width.screenPoints, height: self.height.screenPoints) }
    }
}
