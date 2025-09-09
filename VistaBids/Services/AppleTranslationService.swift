import Foundation
import NaturalLanguage

/// Protocol defining the translation service interface
protocol TranslationService {
    func translateText(_ text: String, to targetLanguage: String) async throws -> String
    func detectLanguage(_ text: String) -> String?
}

/// Translation service using Apple's NaturalLanguage framework
class AppleTranslationService: TranslationService {
    private let supportedLanguages = ["en", "es", "fr", "de", "ja", "zh", "ru", "ar", "hi", "pt", "it", "ko", "nl"]
    
    /// Translates text to the target language
    /// - Parameters:
    ///   - text: The text to translate
    ///   - targetLanguage: The language code to translate to (e.g., "en", "es", "fr")
    /// - Returns: The translated text
    func translateText(_ text: String, to targetLanguage: String) async throws -> String {
        // For a real implementation, you would use a proper translation API like AWS Translate, Google Translate, etc.
        // This is a simulated implementation for development purposes
        
        // First detect the source language
        let sourceLanguage = detectLanguage(text) ?? "en"
        
        // If the source and target languages are the same, return the original text
        if sourceLanguage == targetLanguage {
            return text
        }
        
        // In a real app, you would call a translation API here
        // For demonstration purposes, we'll use a mock translation
        return try await simulateTranslation(text, from: sourceLanguage, to: targetLanguage)
    }
    
    /// Detects the language of the given text
    /// - Parameter text: The text to analyze
    /// - Returns: The language code or nil if detection failed
    func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage?.rawValue else {
            return nil
        }
        
        // Convert NL language tags to our simplified language codes
        switch language {
        case "en": return "en"
        case "es": return "es"
        case "fr": return "fr"
        case "de": return "de"
        case "ja": return "ja"
        case "zh-Hans", "zh-Hant": return "zh"
        case "ru": return "ru"
        case "ar": return "ar"
        case "hi": return "hi"
        case "pt": return "pt"
        case "it": return "it"
        case "ko": return "ko"
        case "nl": return "nl"
        default: return "en" // Default to English if unsupported
        }
    }
    
    /// Simulates translation process for development purposes
    /// - Parameters:
    ///   - text: The text to translate
    ///   - sourceLanguage: The source language code
    ///   - targetLanguage: The target language code
    /// - Returns: A simulated translation
    private func simulateTranslation(_ text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        // Add a small delay to simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simple dictionary of common phrases in different languages for demo purposes
        let translations: [String: [String: String]] = [
            "Hello": ["en": "Hello", "es": "Hola", "fr": "Bonjour", "de": "Hallo", "ja": "こんにちは", "zh": "你好"],
            "How are you?": ["en": "How are you?", "es": "¿Cómo estás?", "fr": "Comment ça va?", "de": "Wie geht es dir?", "ja": "お元気ですか？", "zh": "你好吗？"],
            "Thank you": ["en": "Thank you", "es": "Gracias", "fr": "Merci", "de": "Danke", "ja": "ありがとう", "zh": "谢谢"],
            "Yes": ["en": "Yes", "es": "Sí", "fr": "Oui", "de": "Ja", "ja": "はい", "zh": "是的"],
            "No": ["en": "No", "es": "No", "fr": "Non", "de": "Nein", "ja": "いいえ", "zh": "不是"],
            "Property": ["en": "Property", "es": "Propiedad", "fr": "Propriété", "de": "Immobilie", "ja": "物件", "zh": "房产"],
            "Real Estate": ["en": "Real Estate", "es": "Bienes Raíces", "fr": "Immobilier", "de": "Immobilien", "ja": "不動産", "zh": "房地产"],
            "Auction": ["en": "Auction", "es": "Subasta", "fr": "Enchère", "de": "Auktion", "ja": "オークション", "zh": "拍卖"],
            "Bidding": ["en": "Bidding", "es": "Oferta", "fr": "Enchères", "de": "Bieten", "ja": "入札", "zh": "投标"],
            "House": ["en": "House", "es": "Casa", "fr": "Maison", "de": "Haus", "ja": "家", "zh": "房子"],
            "Apartment": ["en": "Apartment", "es": "Apartamento", "fr": "Appartement", "de": "Wohnung", "ja": "アパート", "zh": "公寓"],
            "Price": ["en": "Price", "es": "Precio", "fr": "Prix", "de": "Preis", "ja": "価格", "zh": "价格"],
            "Location": ["en": "Location", "es": "Ubicación", "fr": "Emplacement", "de": "Standort", "ja": "場所", "zh": "位置"],
            "Sale": ["en": "Sale", "es": "Venta", "fr": "Vente", "de": "Verkauf", "ja": "販売", "zh": "销售"],
            "Buy": ["en": "Buy", "es": "Comprar", "fr": "Acheter", "de": "Kaufen", "ja": "購入", "zh": "购买"],
            "Sell": ["en": "Sell", "es": "Vender", "fr": "Vendre", "de": "Verkaufen", "ja": "売る", "zh": "出售"],
            "Investment": ["en": "Investment", "es": "Inversión", "fr": "Investissement", "de": "Investition", "ja": "投資", "zh": "投资"],
            "Market": ["en": "Market", "es": "Mercado", "fr": "Marché", "de": "Markt", "ja": "市場", "zh": "市场"]
        ]
        
        // For a simple demo, we'll check if the text contains any of our known phrases and replace them
        var translatedText = text
        
        for (phrase, languageMap) in translations {
            if text.lowercased().contains(phrase.lowercased()) {
                if let sourcePhrase = findKeyForSourceLanguage(phrase, languageMap, sourceLanguage),
                   let targetPhrase = languageMap[targetLanguage] {
                    translatedText = translatedText.replacingOccurrences(
                        of: sourcePhrase,
                        with: targetPhrase,
                        options: .caseInsensitive
                    )
                }
            }
        }
        
        // If the text wasn't changed by our simple translation, append a note
        if translatedText == text {
            translatedText += " [Translated to \(languageName(for: targetLanguage))]"
        }
        
        return translatedText
    }
    
    /// Finds the key in the language map that corresponds to the source language
    private func findKeyForSourceLanguage(_ originalKey: String, _ languageMap: [String: String], _ sourceLanguage: String) -> String? {
        // First try the direct match
        if let sourceValue = languageMap[sourceLanguage] {
            // Find the key that has this value
            for (key, value) in languageMap {
                if value == sourceValue {
                    return key
                }
            }
        }
        
        // If no direct match, return the original key
        return originalKey
    }
    
    /// Returns a human-readable language name for a language code
    private func languageName(for code: String) -> String {
        switch code {
        case "en": return "English"
        case "es": return "Spanish"
        case "fr": return "French"
        case "de": return "German"
        case "ja": return "Japanese"
        case "zh": return "Chinese"
        case "ru": return "Russian"
        case "ar": return "Arabic"
        case "hi": return "Hindi"
        case "pt": return "Portuguese"
        case "it": return "Italian"
        case "ko": return "Korean"
        case "nl": return "Dutch"
        default: return code.uppercased()
        }
    }
}
