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
    private let analysisWindowSize = 100 // Number of words to analyze
    
    private var cache: [String: CodeEditor.Language] = [:]
    private var lastAnalyzedWords: [String] = []
    
    init() {
        self.supportedLanguages = [.bash, .c, .cpp, .css, .http, .java, .javascript, .json, .markdown, .makefile, .objectivec, .python, .php, .ruby, .sql, .swift]
    }

    func detectLanguage(in text: String) -> CodeEditor.Language {
        if let cachedLanguage = cache[text] {
            return cachedLanguage
        }
        
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Check if only whitespace or newlines were added
        if words == lastAnalyzedWords {
            return cache[text] ?? .markdown
        }
        
        let detectedLanguage: CodeEditor.Language
        
        if lastAnalyzedWords.isEmpty || !words.starts(with: lastAnalyzedWords) {
            detectedLanguage = analyzeWords(words)
        } else {
            let additionalWords = Array(words.dropFirst(lastAnalyzedWords.count))
            detectedLanguage = analyzeWords(additionalWords)
        }
        
        lastAnalyzedWords = words
        cache[text] = detectedLanguage
        return detectedLanguage
    }
    
    private func keywordWeight(for language: CodeEditor.Language) -> Double {
        language == .json ? 0.1 : 1.5
    }
    
    private func analyzeWords(_ words: [String]) -> CodeEditor.Language {
        let windowedWords = Array(words.suffix(analysisWindowSize))
        
        var scores: [CodeEditor.Language: Double] = [:]
        for language in supportedLanguages {
            scores[language] = 0
        }
        
        // Keyword matching
        for (language, keywords) in LanguageData.keywordMap {
            let keywordMatches = Set(windowedWords).intersection(keywords)
            scores[language, default: 0] += Double(keywordMatches.count) * (keywordWeight(for: language))
        }
        
        // Normalize scores based on input length
        let wordCount = Double(windowedWords.count)
        for language in supportedLanguages {
            scores[language] = (scores[language] ?? 0) / wordCount
        }
        
        return scores.max(by: { $0.value < $1.value })?.key ?? .markdown
    }
}
