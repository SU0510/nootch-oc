//
//  Note.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI
import SwiftDate
import SwiftData
import CodeEditor

@Model
final class Note {
    @Attribute(.transformable(by: NSAttributedStringTransformer.name.rawValue)) var richText = NSAttributedString() {
        willSet {
            self.updatedAt = Date()
        }
    }
    var codeText = ""
    var codeLanguage = CodeEditor.Language.markdown.rawValue
    var createdAt: Date
    var updatedAt: Date
    var icon: String = "circle"
    var scrollPos: Double = 0
    var isCodeMode: Bool = false
    
    init(icon: String, richText: NSAttributedString = NSAttributedString(string: ""), codeText: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.icon = icon
        self.richText = richText
        self.codeText = codeText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func exportToTXT() -> Data? {
        return self.richText.string.data(using: .utf8)
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
            return data
        }
        return nil
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        if let attrStr = try? NSAttributedString(data: data, format: .archivedData) {
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
