//
//  ScrollableDaysView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/06/24.
//

import SwiftUI

struct ScrollableDaysView: View {
    var body: some View {
        ScrollWheelViewRepresentable(onDragChanged: onDragChanged, onDragEnded: onDragEnded) {
            HStack {
                LazyHStack {
                    
                }
            }
        }
    }
    
    // MARK: - Functions
    func onDragChanged(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> ()) {
    }
    
    func onDragEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
//        cancelPan = false
    }
    
}
