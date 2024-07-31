//
//  fadeOnEdges.swift
//  NotchNook
//
//  Created by Igor Marcossi on 16/06/24.
//

import SwiftUI
import SmoothGradient

extension View {
    func fadeOnEdges(axis: Axis, fadeLength: Double, curve: UnitCurve = .easeInOut, disable: Bool = false) -> some View {
        self.fadeOnEdges(axis: axis, topLeadingFadeLength: fadeLength, bottomTrailingFadeLength: fadeLength, curveStart: curve, curveEnd: curve, disable: disable)
    }
    func fadeOnEdges(axis: Axis, topLeadingFadeLength: Double, bottomTrailingFadeLength: Double, curve: UnitCurve = .easeInOut, disable: Bool = false) -> some View {
        self.fadeOnEdges(axis: axis, topLeadingFadeLength: topLeadingFadeLength, bottomTrailingFadeLength: bottomTrailingFadeLength, curveStart: curve, curveEnd: curve, disable: disable)
    }
    func fadeOnEdges(axis: Axis, topLeadingFadeLength: Double, bottomTrailingFadeLength: Double, curveStart: UnitCurve = .easeInOut, curveEnd: UnitCurve = .easeInOut, disable: Bool = false) -> some View {
        self
            .mask {
                if !disable {
                    GeometryReader { geo in
                        DynStack(direction: axis, spacing: 0) {
                            SmoothLinearGradient(
                                from: .black.opacity(0),
                                to: .black.opacity(1),
                                startPoint: axis == .horizontal ? .leading : .top,
                                endPoint: axis == .horizontal ? .trailing : .bottom,
                                curve: curveStart
                            )
                            .frame(width: axis == .horizontal ? topLeadingFadeLength : nil, height: axis == .vertical ? topLeadingFadeLength : nil)
                            Color.black.frame(maxWidth: .infinity)
                            SmoothLinearGradient(
                                from: .black.opacity(0),
                                to: .black.opacity(1),
                                startPoint: axis == .horizontal ? .trailing : .bottom,
                                endPoint: axis == .horizontal ? .leading : .top,
                                curve: curveEnd
                            )
                            .frame(width: axis == .horizontal ? bottomTrailingFadeLength : nil, height: axis == .vertical ? bottomTrailingFadeLength : nil)
                        }
                    }
                } else {
                    Color.black
                }
            }
    }
    func fadeOnEnd(axis: Axis, fadeLength: Double, disable: Bool = false) -> some View {
        self
            .mask {
                if !disable {
                    GeometryReader { geo in
                        DynStack(direction: axis, spacing: 0) {
                            Color.black.frame(maxWidth: .infinity)
                            SmoothLinearGradient(
                                from: .black.opacity(0),
                                to: .black.opacity(1),
                                startPoint: axis == .horizontal ? .trailing : .bottom,
                                endPoint: axis == .horizontal ? .leading : .top,
                                curve: .easeInOut
                            )
                            .frame(width: axis == .horizontal ? fadeLength : nil, height: axis == .vertical ? fadeLength : nil)
                        }
                    }
                } else {
                    Color.black
                }
            }
    }
}

struct DynStack<C: View>: View {
    var direction: Axis
    var spacing: Double
    @ViewBuilder var content: () -> C
    var body: some View {
        if direction == .vertical {
            VStack(spacing: spacing) {
                content()
            }
        } else {
            HStack(spacing: spacing) {
                content()
            }
        }
    }
}
