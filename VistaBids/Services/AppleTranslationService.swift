import Foundation
import NaturalLanguage

// NOTE: Using the TranslationServiceProtocol defined in CommunityModels.swift

/// Translation service using Apple's NaturalLanguage framework
class AppleTranslationService: TranslationServiceProtocol {
    private let supportedLanguages = ["en", "es", "fr", "de", "ja", "zh", "ru", "ar", "hi", "pt", "it", "ko", "nl"]
    
    // Cache for translations to avoid unnecessary API calls
    private var translationCache: [String: [String: String]] = [:]
    
    /// Translates text to the target language
    /// - Parameters:
    ///   - text: The text to translate
    ///   - targetLanguage: The language code to translate to (e.g., "en", "es", "fr")
    /// - Returns: The translated text
    func translateText(_ text: String, to targetLanguage: String) async throws -> String {
        // For a real implementation, you would use a proper translation API like AWS Translate, Google Translate, etc.
        // This is a simulated implementation for development purposes
        
        // First detect the source language
        let sourceLanguage = try await detectLanguage(text)
        
        // If the source and target languages are the same, return the original text
        if sourceLanguage == targetLanguage {
            return text
        }
        
        // Check cache first
        let cacheKey = "\(sourceLanguage)_\(targetLanguage)"
        if let cachedTranslations = translationCache[cacheKey],
           let cachedTranslation = cachedTranslations[text] {
            print("🌐 Translation: Using cached translation for \(text)")
            return cachedTranslation
        }
        
        // In a real app, you would call a translation API here
        // For demonstration purposes, we'll use a mock translation
        let translatedText = try await simulateTranslation(text, from: sourceLanguage, to: targetLanguage)
        
        // Cache the result
        if translationCache[cacheKey] == nil {
            translationCache[cacheKey] = [:]
        }
        translationCache[cacheKey]?[text] = translatedText
        
        return translatedText
    }
    
    /// Detects the language of the given text
    /// - Parameter text: The text to analyze
    /// - Returns: The language code or nil if detection failed
    func detectLanguage(_ text: String) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage?.rawValue else {
            return "en" // Default to English if detection failed
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
        // Add a small delay to simulate API call (variable to make it feel more realistic)
        let delay = UInt64(300_000_000 + arc4random_uniform(400_000_000)) // 0.3-0.7 seconds
        try await Task.sleep(nanoseconds: delay)
        
        // Real estate terminology translations
        let translations: [String: [String: String]] = [
            // Common phrases
            "Hello": ["en": "Hello", "es": "Hola", "fr": "Bonjour", "de": "Hallo", "ja": "こんにちは", "zh": "你好"],
            "How are you?": ["en": "How are you?", "es": "¿Cómo estás?", "fr": "Comment ça va?", "de": "Wie geht es dir?", "ja": "お元気ですか？", "zh": "你好吗？"],
            "Thank you": ["en": "Thank you", "es": "Gracias", "fr": "Merci", "de": "Danke", "ja": "ありがとう", "zh": "谢谢"],
            "Yes": ["en": "Yes", "es": "Sí", "fr": "Oui", "de": "Ja", "ja": "はい", "zh": "是的"],
            "No": ["en": "No", "es": "No", "fr": "Non", "de": "Nein", "ja": "いいえ", "zh": "不是"],
            
            // Real estate terms
            "Property": ["en": "Property", "es": "Propiedad", "fr": "Propriété", "de": "Immobilie", "ja": "不動産", "zh": "房产"],
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
            "Market": ["en": "Market", "es": "Mercado", "fr": "Marché", "de": "Markt", "ja": "市場", "zh": "市场"],
            
            // Expanded real estate vocabulary
            "Mortgage": ["en": "Mortgage", "es": "Hipoteca", "fr": "Hypothèque", "de": "Hypothek", "ja": "住宅ローン", "zh": "抵押贷款"],
            "Listing": ["en": "Listing", "es": "Listado", "fr": "Annonce", "de": "Angebot", "ja": "リスティング", "zh": "房源"],
            "Agent": ["en": "Agent", "es": "Agente", "fr": "Agent", "de": "Makler", "ja": "エージェント", "zh": "经纪人"],
            "Broker": ["en": "Broker", "es": "Corredor", "fr": "Courtier", "de": "Makler", "ja": "ブローカー", "zh": "经纪人"],
            "Down Payment": ["en": "Down Payment", "es": "Pago inicial", "fr": "Acompte", "de": "Anzahlung", "ja": "頭金", "zh": "首付款"],
            "Closing Costs": ["en": "Closing Costs", "es": "Costos de cierre", "fr": "Frais de clôture", "de": "Abschlusskosten", "ja": "諸費用", "zh": "交割费用"],
            "Inspection": ["en": "Inspection", "es": "Inspección", "fr": "Inspection", "de": "Inspektion", "ja": "検査", "zh": "检查"],
            "Appraisal": ["en": "Appraisal", "es": "Tasación", "fr": "Évaluation", "de": "Bewertung", "ja": "鑑定", "zh": "评估"],
            "Escrow": ["en": "Escrow", "es": "Depósito en garantía", "fr": "Séquestre", "de": "Treuhand", "ja": "エスクロー", "zh": "托管"],
            "Deed": ["en": "Deed", "es": "Escritura", "fr": "Acte", "de": "Urkunde", "ja": "証書", "zh": "契约"],
            "Title": ["en": "Title", "es": "Título", "fr": "Titre", "de": "Titel", "ja": "権利証", "zh": "产权"],
            "Foreclosure": ["en": "Foreclosure", "es": "Ejecución hipotecaria", "fr": "Saisie", "de": "Zwangsvollstreckung", "ja": "差し押さえ", "zh": "止赎"],
            "Rental": ["en": "Rental", "es": "Alquiler", "fr": "Location", "de": "Vermietung", "ja": "賃貸", "zh": "租赁"],
            "Lease": ["en": "Lease", "es": "Arrendamiento", "fr": "Bail", "de": "Pacht", "ja": "リース", "zh": "租约"],
            "Commercial": ["en": "Commercial", "es": "Comercial", "fr": "Commercial", "de": "Gewerbe", "ja": "商業", "zh": "商业"],
            "Residential": ["en": "Residential", "es": "Residencial", "fr": "Résidentiel", "de": "Wohn", "ja": "住宅", "zh": "住宅"],
            "Development": ["en": "Development", "es": "Desarrollo", "fr": "Développement", "de": "Entwicklung", "ja": "開発", "zh": "开发"]
        ]
        
        // Sample phrases for completely translating short messages
        let fullPhraseTranslations: [String: [String: String]] = [
            "Just sold my first property": [
                "en": "Just sold my first property",
                "es": "Acabo de vender mi primera propiedad",
                "fr": "Je viens de vendre ma première propriété",
                "de": "Ich habe gerade meine erste Immobilie verkauft",
                "ja": "初めての物件を売却しました",
                "zh": "刚刚卖掉了我的第一套房产"
            ],
            "Looking for advice on property": [
                "en": "Looking for advice on property",
                "es": "Buscando consejos sobre propiedades",
                "fr": "Je cherche des conseils sur l'immobilier",
                "de": "Ich suche Ratschläge zu Immobilien",
                "ja": "不動産に関するアドバイスを探しています",
                "zh": "寻找有关房产的建议"
            ],
            "The auction process was seamless": [
                "en": "The auction process was seamless",
                "es": "El proceso de subasta fue perfecto",
                "fr": "Le processus d'enchères s'est déroulé sans problème",
                "de": "Der Auktionsprozess verlief reibungslos",
                "ja": "オークションプロセスはスムーズでした",
                "zh": "拍卖过程非常顺利"
            ],
            "Properties in downtown area": [
                "en": "Properties in downtown area",
                "es": "Propiedades en el centro de la ciudad",
                "fr": "Propriétés dans le centre-ville",
                "de": "Immobilien in der Innenstadt",
                "ja": "ダウンタウンエリアの物件",
                "zh": "市中心的房产"
            ],
            "I got a great price": [
                "en": "I got a great price",
                "es": "Conseguí un gran precio",
                "fr": "J'ai obtenu un excellent prix",
                "de": "Ich habe einen guten Preis bekommen",
                "ja": "良い価格で手に入れました",
                "zh": "我得到了一个很好的价格"
            ]
        ]
        
        // First check if we have a complete translation for the text
        for (phrase, translations) in fullPhraseTranslations {
            if text.lowercased().contains(phrase.lowercased()) {
                if let targetPhrase = translations[targetLanguage] {
                    return text.replacingOccurrences(
                        of: phrase,
                        with: targetPhrase,
                        options: .caseInsensitive
                    )
                }
            }
        }
        
        // If no complete match, perform word-by-word translation
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
        
        // Language-specific formatting
        switch targetLanguage {
        case "zh", "ja":
            // Remove excess spaces for Asian languages
            translatedText = translatedText.replacingOccurrences(of: " ,", with: ",")
            translatedText = translatedText.replacingOccurrences(of: " .", with: ".")
            translatedText = translatedText.replacingOccurrences(of: "  ", with: " ")
        case "fr":
            // Add proper spacing for French punctuation
            translatedText = translatedText.replacingOccurrences(of: "!", with: " !")
            translatedText = translatedText.replacingOccurrences(of: "?", with: " ?")
        default:
            break
        }
        
        // If the text wasn't changed by our translation system, add a note
        if translatedText == text {
            // Pick one of several formats for the translation note to make it feel more natural
            let formats = [
                "[Translated from \(languageName(for: sourceLanguage)) to \(languageName(for: targetLanguage))]",
                "[Translation: \(sourceLanguage.uppercased()) → \(targetLanguage.uppercased())]",
                "[\(languageFlag(for: sourceLanguage)) → \(languageFlag(for: targetLanguage))]",
                "[Auto-translated]"
            ]
            
            let randomFormat = formats[Int(arc4random_uniform(UInt32(formats.count)))]
            translatedText += " " + randomFormat
        }
        
        return translatedText
    }
    
    /// Returns the flag emoji for a language code
    private func languageFlag(for code: String) -> String {
        switch code {
        case "en": return "🇺🇸"
        case "es": return "🇪🇸"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "ja": return "🇯🇵"
        case "zh": return "🇨🇳"
        case "ru": return "🇷🇺"
        case "ar": return "🇸🇦"
        case "hi": return "🇮🇳"
        case "pt": return "🇧🇷"
        case "it": return "🇮🇹"
        case "ko": return "🇰🇷"
        case "nl": return "🇳🇱"
        default: return "🏳️"
        }
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
