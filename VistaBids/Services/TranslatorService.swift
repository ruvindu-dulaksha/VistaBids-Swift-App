//
//  TranslatorService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-18.
//

import Foundation

enum Language: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case english = "English"
    case sinhala = "Sinhala"
    case tamil = "Tamil"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .auto: return "Auto Detect"
        case .english: return "English"
        case .sinhala: return "සිංහල"
        case .tamil: return "தமிழ்"
        }
    }
}

@MainActor
class TranslatorService: ObservableObject, TranslationServiceProtocol {
    static let shared = TranslatorService()
    
    @Published var isTranslating = false
    
    private init() {}
    
    // TranslationServiceProtocol methods
    func translateText(_ text: String, to targetLanguage: String) async throws -> String {
        let fromLanguage = try await detectLanguageEnum(text: text)
        let toLanguage = languageFromString(targetLanguage)
        return try await translate(text: text, from: fromLanguage, to: toLanguage)
    }
    
    func detectLanguage(_ text: String) async throws -> String {
        let detected = try await detectLanguageEnum(text: text)
        return detected.rawValue
    }
    
    // Helper method to convert string to Language enum
    private func languageFromString(_ languageCode: String) -> Language {
        switch languageCode.lowercased() {
        case "en", "english": return .english
        case "si", "sinhala", "සිංහල": return .sinhala
        case "ta", "tamil", "தமிழ்": return .tamil
        default: return .english
        }
    }
    
    func translate(text: String, from: Language, to: Language) async throws -> String {
        isTranslating = true
        defer { isTranslating = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simple translation dictionary for demo
        let translations: [String: [Language: String]] = [
            "hello": [
                .sinhala: "ආයුබෝවන්",
                .tamil: "வணக்கம்",
                .english: "Hello"
            ],
            "how are you": [
                .sinhala: "ඔබට කොහොමද",
                .tamil: "எப்படி இருக்கிறீர்கள்",
                .english: "How are you"
            ],
            "thank you": [
                .sinhala: "ස්තුතියි",
                .tamil: "நன்றி",
                .english: "Thank you"
            ],
            "good morning": [
                .sinhala: "සුභ උදෑසනක්",
                .tamil: "காலை வணக்கம்",
                .english: "Good morning"
            ],
            "good night": [
                .sinhala: "සුභ රාත්‍රියක්",
                .tamil: "இரவு நல்வாழ்த்துகள்",
                .english: "Good night"
            ],
            "property": [
                .sinhala: "වතු",
                .tamil: "சொத்து",
                .english: "Property"
            ],
            "auction": [
                .sinhala: "ලිල්ල",
                .tamil: "ஏலம்",
                .english: "Auction"
            ],
            "bid": [
                .sinhala: "උත්සාහය",
                .tamil: "ஏலம்",
                .english: "Bid"
            ],
            "price": [
                .sinhala: "මිල",
                .tamil: "விலை",
                .english: "Price"
            ],
            "land": [
                .sinhala: "භූමිය",
                .tamil: "நிலம்",
                .english: "Land"
            ],
            "flowers": [
                .sinhala: "මල්",
                .tamil: "பூக்கள்",
                .english: "Flowers"
            ],
            "nice": [
                .sinhala: "හොඳ",
                .tamil: "நல்ல",
                .english: "Nice"
            ],
            "my": [
                .sinhala: "මගේ",
                .tamil: "எனது",
                .english: "My"
            ],
            "i": [
                .sinhala: "මම",
                .tamil: "நான்",
                .english: "I"
            ],
            "you": [
                .sinhala: "ඔබ",
                .tamil: "நீங்கள்",
                .english: "You"
            ],
            "is": [
                .sinhala: "වේ",
                .tamil: "இருக்கிறது",
                .english: "Is"
            ],
            "are": [
                .sinhala: "වේ",
                .tamil: "இருக்கிறீர்கள்",
                .english: "Are"
            ],
            "this": [
                .sinhala: "මෙය",
                .tamil: "இது",
                .english: "This"
            ],
            "that": [
                .sinhala: "එය",
                .tamil: "அது",
                .english: "That"
            ]
        ]
        
        let lowerText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if we have a translation for this text
        if let textTranslations = translations[lowerText], let translation = textTranslations[to] {
            return translation
        }
        
        // If no exact match, try to translate word by word
        let words = lowerText.split(separator: " ")
        var translatedWords: [String] = []
        
        for word in words {
            let wordStr = String(word)
            if let wordTranslations = translations[wordStr], let translation = wordTranslations[to] {
                translatedWords.append(translation)
            } else {
                // If no translation, keep original word
                translatedWords.append(wordStr)
            }
        }
        
        if translatedWords.count > 1 {
            return translatedWords.joined(separator: " ")
        }
        
        // If no translation found, return mock translation
        if to == .auto {
            return text // No translation needed
        }
        
        return "[\(to.displayName)] \(text)"
    }
    
    func detectLanguageEnum(text: String) async throws -> Language {
        // Simple language detection for demo
        let sinhalaChars = CharacterSet(charactersIn: "අආඇඈඉඊඋඌඍඎඏඐඑඒඓඔඕඖකඛගඝඞඟචඡජඣඤඥඦටඨඩඪණඬතථදධනඳපඵබභමඹයරලවශෂසහළෆාැෑිීුූෘෙේෛොෝෞෟ෠෡෢෣෤෥෦෧෨෩෪෫෬෭෮෯෰෱")
        let tamilChars = CharacterSet(charactersIn: "அஆஇஈஉஊஎஏஐஒஓஔகஙசஜஞடணதநபமயரலவழளறன")
        
        if text.rangeOfCharacter(from: sinhalaChars) != nil {
            return .sinhala
        } else if text.rangeOfCharacter(from: tamilChars) != nil {
            return .tamil
        } else {
            return .english
        }
    }
}