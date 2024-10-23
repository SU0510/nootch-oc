//
//  LanguageDetector.swift
//  NotchNook
//
//  Created by Lori Montenegro on 15/10/24.
//

import Foundation
import CodeEditor

class LanguageDetector {
    
    private let supportedLanguages: [CodeEditor.Language]
    private let regexWeight: Double = 3.0
    private let analysisWindowSize = 1000
    
    private var cache: [String: CodeEditor.Language] = [:]
    private var lastAnalyzedText: String = ""
    
    init() {
        self.supportedLanguages = [.bash, .c, .cpp, .css, .http, .java, .javascript, .json, .markdown, .makefile, .objectivec, .python, .php, .ruby, .sql, .swift]
    }

    func detectLanguage(in text: String) -> CodeEditor.Language {
        if let cachedLanguage = cache[text] {
            return cachedLanguage
        }
        
        let newText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if only whitespace or newlines were added
        if newText == lastAnalyzedText.trimmingCharacters(in: .whitespacesAndNewlines) {
            return cache[lastAnalyzedText] ?? .markdown
        }
        
        let detectedLanguage: CodeEditor.Language
        
        if lastAnalyzedText.isEmpty || !newText.hasPrefix(lastAnalyzedText) {
            detectedLanguage = analyzeText(newText)
        } else {
            let additionalText = String(newText.dropFirst(lastAnalyzedText.count))
            detectedLanguage = analyzeText(additionalText)
        }
        
        lastAnalyzedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        cache[newText.trimmingCharacters(in: .whitespacesAndNewlines)] = detectedLanguage
        return detectedLanguage
    }
    
    private func keywordWeight(for language: CodeEditor.Language) -> Double {
        language == .json ? 0.1 : 1.5
    }
    
    private func analyzeText(_ text: String) -> CodeEditor.Language {
        let windowedText = String(text.suffix(analysisWindowSize))
        
        var scores: [CodeEditor.Language: Double] = [:]
        for language in supportedLanguages {
            scores[language] = 0
        }
        
        let words = windowedText.components(separatedBy: .whitespacesAndNewlines)
        
        // Keyword matching
        for (language, keywords) in LanguageData.keywordMap {
            let keywordMatches = Set(words).intersection(keywords)
            scores[language, default: 0] += Double(keywordMatches.count) * (keywordWeight(for: language))
        }
        
        // Normalize scores based on input length
        let textLength = Double(windowedText.count)
        for language in supportedLanguages {
            scores[language] = (scores[language] ?? 0) / textLength
        }
        
        return scores.max(by: { $0.value < $1.value })?.key ?? .markdown
    }
}
