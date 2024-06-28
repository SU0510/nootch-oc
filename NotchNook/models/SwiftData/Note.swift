//
//  Note.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI
import SwiftDate
import SwiftData

@Model
final class Note {
    @Attribute(.transformable(by: NSAttributedStringTransformer.name.rawValue)) var text: NSAttributedString
    var createdAt: Date
    var updatedAt: Date
    
    init(text: NSAttributedString = NSAttributedString(string: ""), createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@objc(NSAttributedStringTransformer)
class NSAttributedStringTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSAttributedString.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let attributedString = value as? NSAttributedString else { return nil }
        if let data = try? attributedString.richTextData(for: .archivedData) {
            return NSData(data: data)
        }
        return nil
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        if let attrStr = try? NSAttributedString(data: Data(referencing: data), format: .archivedData) {
            return attrStr
        }
        return nil
    }
}

extension NSAttributedStringTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: NSAttributedStringTransformer.self))
    
    public static func register() {
        let transformer = NSAttributedStringTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
