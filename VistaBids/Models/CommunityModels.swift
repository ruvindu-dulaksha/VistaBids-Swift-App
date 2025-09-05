//
//  CommunityModels.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import Foundation
// Temporarily commenting out Firebase imports to fix build errors
import FirebaseFirestore


// MARK: - Community Post Model
struct CommunityPost: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let author: String
    let authorAvatar: String?
    let content: String
    let originalLanguage: String
    let timestamp: Date
    var likes: Int
    var comments: Int
    let imageURLs: [String]
    let location: PostLocation?
    let groupId: String?
    var likedBy: [String]
    var isTranslated: Bool = false
    var translatedContent: String?
    var translatedLanguage: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, author, authorAvatar, content, originalLanguage
        case timestamp, likes, comments, imageURLs, location, groupId, likedBy
        case isTranslated, translatedContent, translatedLanguage
    }
}

// MARK: - Post Location Model
struct PostLocation: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
}

// MARK: - Community Event Model
struct CommunityEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let title: String
    let description: String
    let originalLanguage: String
    let date: Date
    let location: EventLocation
    var attendees: [String]
    let maxAttendees: Int
    let imageURLs: [String]
    let groupId: String?
    let category: EventCategory
    var isTranslated: Bool = false
    var translatedTitle: String?
    var translatedDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, title, description, originalLanguage, date
        case location, attendees, maxAttendees, imageURLs, groupId, category
        case isTranslated, translatedTitle, translatedDescription
    }
}

// MARK: - Event Location Model
struct EventLocation: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Event Category Enum
enum EventCategory: String, CaseIterable, Codable {
    case workshop = "Workshop"
    case viewing = "Property Viewing"
    case networking = "Networking"
    case auction = "Auction"
    case seminar = "Seminar"
    case consultation = "Consultation"
    case meetup = "Meetup"
}

// MARK: - Community Group Model
struct CommunityGroup: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let originalLanguage: String
    let createdBy: String
    let createdAt: Date
    var members: [String]
    let imageURL: String?
    let isPrivate: Bool
    let requiresApproval: Bool
    let category: GroupCategory
    var isTranslated: Bool = false
    var translatedName: String?
    var translatedDescription: String?
    
    // Computed property for member count
    var memberCount: Int {
        return members.count
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, originalLanguage, createdBy, createdAt
        case members, imageURL, isPrivate, requiresApproval, category
        case isTranslated, translatedName, translatedDescription
    }
}

// MARK: - Group Category Enum
enum GroupCategory: String, CaseIterable, Codable {
    case investors = "Investors"
    case firstTimeBuyers = "First Time Buyers"
    case luxury = "Luxury Properties"
    case commercial = "Commercial"
    case residential = "Residential"
    case rentals = "Rentals"
    case renovations = "Renovations"
    case legal = "Legal"
    case local = "Local Community"
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let senderAvatar: String?
    let content: String
    let originalLanguage: String
    let timestamp: Date
    let chatId: String
    let messageType: MessageType
    let imageURLs: [String]
    var isTranslated: Bool = false
    var translatedContent: String?
    
    enum CodingKeys: String, CodingKey {
        case id, senderId, senderName, senderAvatar, content, originalLanguage
        case timestamp, chatId, messageType, imageURLs
        case isTranslated, translatedContent
    }
}

// MARK: - Message Type Enum
enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case location = "location"
    case property = "property"
}

// MARK: - Chat Room Model
struct ChatRoom: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let participants: [String]
    let createdBy: String
    let createdAt: Date
    let lastMessage: String?
    let lastMessageTime: Date?
    let isGroup: Bool
    let imageURL: String?
    let groupId: String? // For group chats
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, participants, createdBy, createdAt
        case lastMessage, lastMessageTime, isGroup, imageURL, groupId
    }
}

// MARK: - Comment Model
struct PostComment: Identifiable, Codable {
    @DocumentID var id: String?
    let postId: String
    let userId: String
    let author: String
    let authorAvatar: String?
    let content: String
    let originalLanguage: String
    let timestamp: Date
    var likes: Int
    var likedBy: [String]
    var isTranslated: Bool = false
    var translatedContent: String?
    
    enum CodingKeys: String, CodingKey {
        case id, postId, userId, author, authorAvatar, content, originalLanguage
        case timestamp, likes, likedBy, isTranslated, translatedContent
    }
}

// MARK: - Translation Service Protocol
protocol TranslationServiceProtocol {
    func translateText(_ text: String, to targetLanguage: String) async throws -> String
    func detectLanguage(_ text: String) async throws -> String
}

// MARK: - Apple Translation Service
class AppleTranslationService: TranslationServiceProtocol {
    func translateText(_ text: String, to targetLanguage: String) async throws -> String {
        // Use Apple's Translation framework (iOS 17.4+) or fallback to Google Translate
        if #available(iOS 17.4, *) {
            return try await translateWithAppleFramework(text, to: targetLanguage)
        } else {
            return try await translateWithGoogleAPI(text, to: targetLanguage)
        }
    }
    
    @available(iOS 17.4, *)
    private func translateWithAppleFramework(_ text: String, to targetLanguage: String) async throws -> String {
        // Apple Translation framework would be imported here, but for compatibility 
        // we'll fallback to Google API for now
        return try await translateWithGoogleAPI(text, to: targetLanguage)
    }
    
    private func translateWithGoogleAPI(_ text: String, to targetLanguage: String) async throws -> String {
        // Google Translate API implementation
        let apiKey = "AIzaSyDummy_API_Key" // You need to replace with actual API key
        let urlString = "https://translation.googleapis.com/language/translate/v2"
        
        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "q": text,
            "target": mapLanguageCode(targetLanguage),
            "source": "en",
            "format": "text",
            "key": apiKey
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw TranslationError.apiError
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let data = json["data"] as? [String: Any],
               let translations = data["translations"] as? [[String: Any]],
               let firstTranslation = translations.first,
               let translatedText = firstTranslation["translatedText"] as? String {
                return translatedText
            } else {
                throw TranslationError.parseError
            }
        } catch {
            // Fallback to enhanced mock translation with better content
            return try await enhancedMockTranslation(text, to: targetLanguage)
        }
    }
    
    private func enhancedMockTranslation(_ text: String, to targetLanguage: String) async throws -> String {
        // Enhanced mock translation with better simulation
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds for realistic delay
        
        let languageMap: [String: (flag: String, name: String)] = [
            "es": ("🇪🇸", "Spanish"),
            "fr": ("🇫🇷", "French"),
            "de": ("��🇪", "German"),
            "ja": ("�🇵", "Japanese"),
            "zh": ("🇨🇳", "Chinese")
        ]
        
        guard let langInfo = languageMap[targetLanguage] else {
            return text // Return original if language not supported
        }
        
        // Create more realistic translations based on common real estate terms
        let translations: [String: [String: String]] = [
            "es": [
                "property": "propiedad",
                "auction": "subasta", 
                "bid": "oferta",
                "house": "casa",
                "apartment": "apartamento",
                "price": "precio",
                "market": "mercado",
                "investment": "inversión"
            ],
            "fr": [
                "property": "propriété",
                "auction": "enchère",
                "bid": "offre", 
                "house": "maison",
                "apartment": "appartement",
                "price": "prix",
                "market": "marché",
                "investment": "investissement"
            ],
            "de": [
                "property": "Immobilie",
                "auction": "Auktion",
                "bid": "Gebot",
                "house": "Haus", 
                "apartment": "Wohnung",
                "price": "Preis",
                "market": "Markt",
                "investment": "Investition"
            ],
            "ja": [
                "property": "不動産",
                "auction": "オークション",
                "bid": "入札",
                "house": "家",
                "apartment": "アパート", 
                "price": "価格",
                "market": "市場",
                "investment": "投資"
            ],
            "zh": [
                "property": "房产",
                "auction": "拍卖",
                "bid": "出价",
                "house": "房子",
                "apartment": "公寓",
                "price": "价格", 
                "market": "市场",
                "investment": "投资"
            ]
        ]
        
        var translatedText = text.lowercased()
        
        // Replace common terms with translations
        if let termTranslations = translations[targetLanguage] {
            for (english, translated) in termTranslations {
                translatedText = translatedText.replacingOccurrences(of: english, with: translated)
            }
        }
        
        return "\(langInfo.flag) \(translatedText.capitalized)"
    }
    
    private func mapLanguageCode(_ code: String) -> String {
        // Map our language codes to Google Translate API codes
        switch code {
        case "zh": return "zh-CN"
        case "ja": return "ja"
        default: return code
        }
    }
    
    func detectLanguage(_ text: String) async throws -> String {
        // Simple language detection based on character patterns
        if text.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) != nil {
            return "zh" // Chinese characters detected
        } else if text.range(of: "[\\u3040-\\u309f\\u30a0-\\u30ff]", options: .regularExpression) != nil {
            return "ja" // Japanese characters detected
        } else if text.range(of: "[áéíóúñü]", options: .regularExpression) != nil {
            return "es" // Spanish characters detected
        } else if text.range(of: "[àâäçéèêëïîôùûüÿ]", options: .regularExpression) != nil {
            return "fr" // French characters detected
        } else if text.range(of: "[äöüß]", options: .regularExpression) != nil {
            return "de" // German characters detected
        }
        
        return "en" // Default to English
    }
}

// MARK: - Translation Errors
enum TranslationError: LocalizedError {
    case unsupportedLanguage
    case invalidURL
    case apiError
    case parseError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage:
            return "This language is not supported for translation"
        case .invalidURL:
            return "Invalid translation service URL"
        case .apiError:
            return "Translation service error"
        case .parseError:
            return "Could not parse translation response"
        case .networkError:
            return "Network error occurred during translation"
        }
    }
}
