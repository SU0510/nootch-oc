//
//  String+Extensions.swift
//  NotchNook
//
//  Created by Lori Montenegro on 27/07/24.
//

import SwiftUI

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: Font) -> CGFloat {
        let nsFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: nsFont], context: nil)
        return ceil(boundingBox.height)
    }
}
